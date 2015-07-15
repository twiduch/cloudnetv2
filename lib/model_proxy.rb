# Just some syntactic sugar to run model methods on a worker process.
# By including this module you can run any method on a worker using Sidekiq's `perform_async()`
# by simply prepending a method call with `.worker`, eg; `worker.long_running_thing()`.
# We take advantage of the fact that it is easy to instantiate a basic model instance with eg;
# `instance = ModelName.find instance.id`. This means that the instance can be easily serialised
# and sent to the worker process.
module ModelProxy
  def worker
    WorkerManager.new self
  end

  # Just a clean class within which we can safely use `method_missing`
  class WorkerManager
    include Cloudnet::Logger

    def initialize(model_instance)
      @instance = model_instance
    end

    # Catch calls like `worker.long_running_thing(args)`, so that `long_running_thing(args)` gets
    # sent to Sidekiq.
    # Careful of the gotcha here. You still need to be told when a valid NameError (undefined
    # local variable or method) is raised
    def method_missing(method, *args, &block)
      if @instance.respond_to? method
        send_to_worker method, *args, &block
      else
        super method, *args, &block
      end
    end

    # Serialise and send the requested method to the Sidekiq queue
    def send_to_worker(method, *args, &block)
      if @instance.new_record?
        # If the the instance hasn't yet been persisted to the DB then the worker will not be
        # able to load the instances attributes from the DB. In which we just serialise them as a
        # hash and send them directly over the wire to the worker queue ourselves.
        identifier = @instance.attributes
      else
        # When the instance already exists in the DB all we need to do to reference it is point
        # to its ID and the worker can load it itself.
        identifier = @instance.id
      end

      ModelWorker.perform_async @instance.class, identifier, method, *args, &block

      return if Cloudnet.environment == 'test'
      ps = Sidekiq::ProcessSet.new
      loggger.warn 'Job queued without any active Sidekiq processes running' if ps.size == 0
    end
  end

  # The actual Sidekiq invocation. Which will likely run on a completely different server somewhere!
  # Here we run exactly the same call made in the model instance, except without the `.worker()`
  # part. So that something like; `instance.worker.long_running_thing(1, 2, 3)`,  becomes;
  # `instance.long_running_thing(1, 2, 3)`.
  class ModelWorker
    include Sidekiq::Worker

    def perform(model_class, identifier, method, *args)
      model = model_class.constantize
      if identifier.is_a? Hash
        # This is for model instances that have not yet been persisted to the DB
        instance = model.new identifier
      else
        # This is for existing model records in the DB
        instance = model.find identifier
      end
      instance.send method, *args
    end
  end
end
