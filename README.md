![Cloud.net logo](https://cloud.net/img/logo.png)

Cloud.net v2: API and Frontend
------------------------------

__The Global Cloud Hosting Marketplace__

A completely reworked implementation of the original Cloud.net application, built from the ground up.

# Installation

This is not a Rails app. The API is a simple Rack app using the [Grape](https://github.com/intridea/grape) gem.
The frontend is single-page JS app, using [mithril.js](http://lhorie.github.io/mithril/index.html).

It follows [Twelve-Factor App](http://12factor.net/) practices. See `Procfile` for required process types.

Requires Ruby 2.x, MongoDB and Redis

# Main components

## User/Server CRUD

Cloud.net is essentially an aesthetic wrapper around the Onapp API, so most of the entities in
Cloud.net are reflected on Onapp. Creating a user on Cloud.net must also create a user on Onapp.
Though not the other way around: creating an Onapp user needn't mean an equivalent Cloud.net user
should exist. The same can be said for Servers and DNS.

However datacentres and templates are created on and retrieved from Onapp, they are not made
on Cloud.net. We simply keep a copy locally for caching and the convenience of DB queries.

## Syncing resource state - Transactions Daemon

As far as possible Cloud.net keeps in sync with the state of Onapp resources through the transaction
log. Any failure in the Transaction Sync daemon stops the daemon. When this happens server states
and usages will not be updated.

## Billing

TBC

## Frontend

The frontend is completely decoupled from the API. It is pure JS and can, or perhaps should, be
hosted on a CDN.

It has its own test suite.

# Glossary

  * 'Onapp': The company behind the Onapp Hypervisor software
  * 'Federation': Onapp's hub through which individual installations of Onapp can harness resources
    from other datacentres that have Onapp installed

# Contributing

TBC

# License

TBC
