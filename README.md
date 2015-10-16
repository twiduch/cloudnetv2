![Cloud.net logo](https://jager.cloud.net/assets/cloudnet.png)

Cloud.net v2: API and Frontend
------------------------------

__The Global Cloud Hosting Marketplace__

A completely reworked implementation of the original Cloud.net application, built from the ground up.

# Installation

This is not a Rails app. The API is a simple Rack app using the [Grape](https://github.com/intridea/grape) gem.
The frontend is single-page JS app, using [mithril.js](http://lhorie.github.io/mithril/index.html).

It follows [Twelve-Factor App](http://12factor.net/) practices. See `Procfile` for required process types.

Requires Ruby 2.x, MongoDB and Redis

## Seed data
To get the currently available datacentres and their OS templates
`rake update_federation_resources`

# Main components

## User/Server CRUD

Cloud.net is essentially an aesthetic wrapper around the OnApp API, so most of the entities in
Cloud.net are reflected on OnApp. Creating a user on Cloud.net must also create a user on OnApp.
Though not the other way around: creating an OnApp user needn't mean an equivalent Cloud.net user
should exist. The same can be said for Servers and DNS.

However, datacentres and templates are created on, and retrieved from, OnApp, they are not made
on Cloud.net. We simply keep a copy locally for caching and the convenience of DB queries.

## Syncing resource state - Transactions Daemon

As far as possible Cloud.net keeps in sync with the state of OnApp resources through the transaction
log. Any failure in the Transaction Sync daemon stops the daemon. When this happens server states
and usages will not be updated.

## Billing

TBC

## Frontend

The frontend is completely decoupled from the API. It is pure JS and can, or perhaps should, be
hosted on a CDN.

Install with `npm install`

Run in development with: `.node_modules/.bin/gulp`

It has its own test suite: `npm test`

# Glossary

  * 'OnApp': The company behind the OnApp Hypervisor software
  * 'Federation': OnApp's hub through which individual installations of OnApp can harness resources
    from other datacentres that have OnApp installed

# Architecture

## Federation

```
+--------------+      +----------------+                      
| DC in Europe |      | DC in Asia     |                      
+------+-------+      +------+---------+                      
       |                     |                                
       |                     |                                
       |               +----------+        +-----------------+
       +---------------|FEDERATION|--------+ DC in Australia |
                       +----------+        +-----------------+
+------------------+      |    |                               
| DC in N. America +------+    |                               
+------------------+           |      +-----------------+      
                               |      | Dedicated OnApp |      
                               +------+   Installtion   |      
                                      |  (without DC)   |      
                                      +--------+--------+      
                                               |               
                                               |               
                                          +----+----+          
                                          |cloud.net|          
                                          +---------+          
```

Where "DC" is a datacentre with OnApp installed.

## Cloud.net

```
+-----------+                              
|Transaction|     +--------+       +------+
|   Sync    +-----+Database+-------+Worker|
|  Daemon   |     +---+----+       |Queue |
+-----------+         |            +------+
                      |                    
                      |                    
               +------+-----+              
         +-----+API Endpoint+-----+        
         |     +------------+     |        
         |                        |        
         |                        |        
    +----+------+            +----+----+   
    |Frontend UI|            |Admin UI |   
    +-----------+            +---------+   
```

# Contributing

TBC

# License

Apache v2.0
