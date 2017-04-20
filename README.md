# Babili Engine <a href="https://travis-ci.org/Babili/engine">![Build status](https://travis-ci.org/Babili/engine.svg?branch=master)</a>


Babili is a real-time chat backend built with Ruby, Rails, Node, Socket.io and Docker.

See https://github.com/Babili/babili for the Getting started guide

The engine is the main service of the API.


## Environment variables

| Option | Default Value | Type | Required? | Description  | Example |
| ---- | ----- | ------ | ----- | ------ | ----- |
| `DB_NAME` | `"engine"`| String | Optional | | `"my_db"` |
| `DB_HOST` | `""`| String | Optional | | `"localhost"` |
| `DB_USER` | `"postgres"`| String | Optional | | `"localhost"` |
| `DB_PORT` | `"5432"`| String | Optional | | `"5432"` |
| `DB_PASSWORD` | `""`| String | Optional | | `"mypwd"` |
| `SIDEKIQ_REDIS_URL` | `""`| String | Required | | `"redis://redis/2"` |
| `RABBITMQ_HOST` | `""`| String | Required | | `"rabbitmq"` |
| `RABBITMQ_PORT` | `""`| String | Required | | `"5672"` |
| `RABBITMQ_USER` | `""`| String | Required | | `"root"` |
| `RABBITMQ_PASSWORD` | `""`| String | Required | | `"root"` |
| `RABBITMQ_EXCHANGE_NAME` | `""`| String | Required | | `"babili"` |
| `RABBITMQ_EXCHANGE_DURABLE` | `""`| String | Required | | `"true"` |
| `SENTRY_DSN` | `""`| String | Optional | | `"https://.."` |


## Rake tasks

### List platforms

    $ rake platforms:list

### Create a new platform

    $ rake platforms:create name=<your platform name>

### Generate a platform api token (for the /platform scope of the API)

    $ rake platforms:generate_api_token name=<your platform name>

## Specify the messages digest webhook url (see section Webhooks below)

    $ rake platforms:set_messages_webhook url=<your url> name=<your platform name>

## Existing api routes: 

```
    GET    /user                                           

    PUT   /user/alive                                      

    GET    /user/rooms                                     
    GET    /user/rooms/:id                                 
    POST   /user/rooms                                     
    PUT    /user/rooms/:id                                 
    DELETE /user/rooms/:id                                 

    GET    /user/rooms/:room_id/messages                   
    POST   /user/rooms/:room_id/messages                   
    DELETE /user/rooms/:room_id/messages/:id               

    POST   /user/rooms/:room_id/memberships                

    PUT    /user/rooms/:room_id/membership                     

    PUT    /user/rooms/:room_id/membership/unread-messages 

    POST   /platform/users/:id/tokens                      
    GET    /platform/users                                 
    POST   /platform/users                                 
    PUT    /platform/users/:id                             
    DELETE /platform/users/:id                             
                  
    GET    /platform/rooms                                 
    GET    /platform/rooms/:id                             
    POST   /platform/rooms                                 
    PUT    /platform/rooms/:id                             
    DELETE /platform/rooms/:id                             

    GET    /platform/rooms/room_id/users                   

    POST   /platform/rooms/:room_id/messages               
    DELETE /platform/rooms/:room_id/messages/:id           

    POST   /platform/rooms/:roomId/users/:userId/membership
    DELETE /platform/rooms/:roomId/users/:userId/membership

    POST   /platform/messages-digests    
```

## Webhooks

### Unread messages digests webhook

You can specify a webhook url that babili will call when a user has pending unread messages using:

    $ rake platforms:set_messages_webhook url=<your url> name=<your platform name>


An unread message is a message written in a room more thant 30 second ago and in which no other messages have been written since at least 30 seconds. Meaning that you receive one webhook per recipient and per room with all unread messages since the last notification.

Babili will retry the webhook until it receives a 200 OK response code.

The payload you will recieve has the following format: 

```
{
    "type": "unread_messages_digest",
    "id": "2aaf2a45-52ea-460e-856e-ae0a340c6a94",
    "relationships": {
        "recipient": {
            "data": {
                "type": "user",
                "id": "af73c3b5-167e-4aa9-a56d-eaa1ce9ff4af"
            }
        },
        "messages": {
            "data": [
                {
                    "type": "message",
                    "id": "b0fa63cd-c41f-4e19-93e6-8a47bcf70ff7",
                    "attributes": {
                        "content": "Hello world",
                        "contentType": "text",
                        "createdAt": "2017-04-18T14:32:24.661Z"
                    },
                    "relationships": {
                        "room": {
                            "data": {
                                "type": "room",
                                "id": "06455982-1407-44be-8f06-655ef1324638"
                            }
                        },
                        "sender": {
                            "data": {
                                "type": "user",
                                "id": "1e14f98c-72b9-41bf-8468-4e744d2b7c61"
                            }
                        }
                    }
                },
               ...
            ]
        },
        "room": {
            "data": {
                "type": "room",
                "id": "06455982-1407-44be-8f06-655ef1324638",
                "name": null
            }
        }
    }
}
```

## Contributors

Babili is the product of the Collaboration of the Spin42 team (http://spin42.com) and the Commuty one (https://www.commuty.net).
