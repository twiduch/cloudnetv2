require 'spec_helper'

describe ModelProxy do
  let(:user) { Fabricate.create :user, id: 1 }

  # Add a fake method
  class User
    def long_running_thing; end
  end

  it 'should proxy a method call to Sidekiq' do
    expect do
      user.worker.long_running_thing
    end.to change(ModelProxy::ModelWorker.jobs, :size).by(1)
  end

  it 'should pass the correct method and args' do
    expect(ModelProxy::ModelWorker).to(
      receive(:perform_async).with(User, user.id, :long_running_thing, 1, 'a', Object)
    )
    user.worker.long_running_thing 1, 'a', Object
  end

  it 'should still raise an error for non-existent methods' do
    expect do
      user.worker.non_existent_method
    end.to raise_exception NoMethodError
  end

  describe 'Running the requested method on a new instance of the model in the worker' do
    it 'should do so for instances *already* persisted to the DB' do
      same_user_different_instance = User.find user.id
      allow(User).to(
        receive(:find).with(user.id).and_return(same_user_different_instance)
      )
      expect(same_user_different_instance).to(
        receive(:long_running_thing).with(1, 'a', Object)
      )
      user.worker.long_running_thing 1, 'a', Object
      ModelProxy::ModelWorker.drain
    end

    it 'should do so for instances *not* yet persisted to the DB' do
      unsaved_user = Fabricate.build(:user)
      expect(User).to_not receive(:find)
      same_user_different_instance = double User
      serialised_user = JSON.parse unsaved_user.attributes.to_json
      expect(User).to(
        receive(:new).with(serialised_user).and_return(same_user_different_instance)
      )
      expect(same_user_different_instance).to(
        receive(:long_running_thing).with(1, 'a', Object)
      )
      unsaved_user.worker.long_running_thing 1, 'a', Object
      ModelProxy::ModelWorker.drain
    end
  end
end
