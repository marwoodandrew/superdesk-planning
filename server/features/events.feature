Feature: Events

    @auth
    Scenario: Empty events list
        Given empty "events"
        When we get "/events"
        Then we get list with 0 items

    @auth
    @notification
    Scenario: Create new events item
        Given empty "users"
        Given empty "locations"
        When we post to "users"
        """
        {"username": "foo", "email": "foo@bar.com", "is_active": true, "sign_off": "abc"}
        """
        Then we get existing resource
        """
        {"_id": "#users._id#", "invisible_stages": []}
        """
        When we post to "/events" with success
        """
        [
            {
                "guid": "123",
                "unique_id": "123",
                "unique_name": "123 name",
                "name": "event 123",
                "definition_short": "short value",
                "definition_long": "long value",
                "relationships":{
                    "broader": "broader value",
                    "narrower": "narrower value",
                    "related": "related value"
                },
                "dates": {
                    "start": "2016-01-02",
                    "end": "2016-01-03"
                },
                "subject": [{"qcode": "test qcaode", "name": "test name"}],
                "location": [{"qcode": "test qcaode", "name": "test name"}],
                "event_contact_info": [{"qcode": "test qcaode", "name": "test name"}]
            }
        ]
        """
        When we get "/events"
        Then we get list with 1 items
        """
            {"_items": [{
                "guid": "__any_value__",
                "original_creator": "__any_value__",
                "name": "event 123",
                "definition_short": "short value",
                "definition_long": "long value"
            }]}
        """
        When we get "/events?sort=[("dates.start",1)]&source={"query":{"range":{"dates.start":{"lte":"2015-01-01T00:00:00.000Z"}}}}"
        Then we get list with 0 items
        When we get "/events?sort=[("dates.start",1)]&source={"query":{"range":{"dates.start":{"gte":"2016-01-02T00:00:00.000Z"}}}}"
        Then we get list with 1 items

    @auth
    @notification
    Scenario: Generate events from recurring rules
        When we post to "events"
        """
        [
            {
                "unique_id": "123",
                "name": "Friday Club",
                "dates": {
                    "start": "2016-11-17T12:00:00.000Z",
                    "end": "2016-11-17T14:00:00.000Z",
                    "tz": "Europe/Berlin",
                    "recurring_rule": {
                        "frequency": "WEEKLY",
                        "interval": 1,
                        "byday": "FR",
                        "count": 3,
                        "endRepeatMode": "count"
                    }
                },
                "occur_status": {
                    "name": "Planned, occurs certainly",
                    "qcode": "eocstat:eos5"
                }
            }
        ]
        """
        Then we get response code 201
        Then we store "EVENT" with first item
        Then we get a list with 3 items
        """
        {"_items": [
            {
                "dates": {
                    "start": "2016-11-18T12:00:00+0000",
                    "end": "2016-11-18T14:00:00+0000"
                },
                "name": "Friday Club"
            }, {
                "dates": {
                    "start": "2016-11-25T12:00:00+0000",
                    "end": "2016-11-25T14:00:00+0000"
                },
                "name": "Friday Club"
            }, {
                "dates": {
                    "start": "2016-12-02T12:00:00+0000",
                    "end": "2016-12-02T14:00:00+0000"
                },
                "name": "Friday Club"
            }
        ]}
        """
        When we get "/events?source={"query":{"match":{"recurrence_id": "#EVENT.recurrence_id#"}}}"
        Then we get list with 3 items

    @auth
    @notification
    Scenario: Prevent to save an event with an existing unique_name
    When we post to "/events" with success
    """
    [
        {
            "unique_name": "JO",
            "name": "JO",
            "dates": {
                "start": "2016-01-02",
                "end": "2016-01-18"
            }
        }
    ]
    """
    And we post to "/events"
    """
    [
        {
            "unique_name": "JO",
            "name": "JO 2022",
            "dates": {
                "start": "2016-01-10",
                "end": "2016-01-18"
            }
        }
    ]
    """
    Then we get error 400


    @auth
    Scenario: Delete an event and it will delete its related plannings and coverages
        Given "events"
        """
        [
            {
                "guid": "123",
                "_id": "123",
                "unique_id": "123",
                "unique_name": "123 name",
                "name": "event 123",
                "definition_short": "short value",
                "definition_long": "long value",
                "relationships":{
                    "broader": "broader value",
                    "narrower": "narrower value",
                    "related": "related value"
                },
                "dates": {
                    "start": "2016-01-02",
                    "end": "2016-01-03"
                },
                "subject": [{"qcode": "test qcaode", "name": "test name"}],
                "location": [{"qcode": "test qcaode", "name": "test name"}],
                "event_contact_info": [{"qcode": "test qcaode", "name": "test name"}]
            }
        ]
        """
        Given "planning"
        """
        [{
            "_id": "P123",
            "item_class": "item class value",
            "headline": "test headline",
            "event_item": "123"
        }]
        """
        Given "coverage"
        """
        [{
            "_id": "C123",
            "planning_item": "P123",
            "planning": {
                "ednote": "test coverage, I want 250 words",
                "assigned_to": "whoever wants to do it"
            }
        }]
        """
        When we delete "/events/123"
        Then we get response code 204
        When we get "/events"
        Then we get list with 0 items
        When we get "/planning/"
        Then we get list with 0 items
        When we get "/coverage/"
        Then we get list with 0 items


    @auth
    @notification
    Scenario: Update a non-recurring event and set it as a recurring event
        When we post to "events"
        """
        [
            {
                "unique_id": "123",
                "name": "Friday Club",
                "dates": {
                    "start": "2016-11-17T23:00:00.000Z",
                    "end": "2016-11-18T00:00:00.000Z",
                    "tz": "Europe/Berlin"
                },
                "occur_status": {
                    "name": "Planned, occurs certainly",
                    "qcode": "eocstat:eos5"
                }
            }
        ]
        """
        Then we get response code 201
        When we patch "/events/#events._id#"
        """
            {
                "name": "Friday Club changed",
                "dates": {
                    "start": "2016-11-17T12:00:00.000Z",
                    "end": "2016-11-17T14:00:00.000Z",
                    "tz": "Europe/Berlin",
                    "recurring_rule": {
                        "frequency": "WEEKLY",
                        "interval": 1,
                        "byday": "FR",
                        "count": 3,
                        "endRepeatMode": "count"
                    }
                }
            }
        """
        Then we get response code 200
        When we get "/events"
        Then we get list with 3 items
        """
            {"_items": [
                  {
                      "dates": {
                          "end": "2016-12-02T14:00:00+0000",
                          "start": "2016-12-02T12:00:00+0000"
                      },
                      "name": "Friday Club changed"
                  },
                  {
                      "dates": {
                          "end": "2016-11-18T14:00:00+0000",
                          "start": "2016-11-18T12:00:00+0000"
                      },
                      "name": "Friday Club changed"
                  },
                  {
                      "dates": {
                          "end": "2016-11-25T14:00:00+0000",
                          "start": "2016-11-25T12:00:00+0000"
                      },
                      "name": "Friday Club changed"
                  }
            ]}
        """


 @auth
    @notification
    Scenario: Update a recurring event but change only that specific recurrence
         When we post to "events"
        """
        [
            {
                "unique_id": "123",
                "name": "Friday Club",
                "dates": {
                    "start": "2016-11-17T23:00:00.000Z",
                    "end": "2016-11-18T00:00:00.000Z",
                    "tz": "Europe/Berlin",
                    "recurring_rule": {
                        "frequency": "WEEKLY",
                        "interval": 1,
                        "byday": "FR",
                        "count": 3,
                        "endRepeatMode": "count"
                    }
                },
                "occur_status": {
                    "name": "Planned, occurs certainly",
                    "qcode": "eocstat:eos5"
                }
            }
        ]
        """
        Then we get response code 201
        Then we store "EVENT" with first item
        When we patch "/events/#EVENT._id#"
        """
            {
                "name": "Friday Club changed",
                "dates": {
                    "start": "2016-11-17T22:00:00.000Z",
                    "end": "2016-11-18T01:00:00.000Z",
                    "tz": "Europe/Berlin",
                    "recurring_rule": null
                }
            }
        """
        Then we get response code 200
        When we get "/events?source={"query":{"match":{"recurrence_id": "#EVENT.recurrence_id#"}}}"
        Then we get list with 2 items
        """
            {"_items": [
                {
                    "name": "Friday Club",
                    "dates": {"start": "2016-11-24T23:00:00+0000", "end": "2016-11-25T00:00:00+0000"}
                },
                {
                    "name": "Friday Club",
                    "dates": {"start": "2016-12-01T23:00:00+0000", "end": "2016-12-02T00:00:00+0000"}
                }
            ]}
        """


 @auth
    @notification
    Scenario: Update a recurring event and change all following recurrences
         When we post to "events"
        """
        [
            {
                "unique_id": "123",
                "name": "Friday Club",
                "dates": {
                    "start": "2016-11-17T10:00:00.000Z",
                    "end": "2016-11-17T11:00:00.000Z",
                    "tz": "Europe/Berlin",
                    "recurring_rule": {
                        "frequency": "WEEKLY",
                        "interval": 1,
                        "byday": "FR",
                        "count": 3,
                        "endRepeatMode": "count"
                    }
                },
                "occur_status": {
                    "name": "Planned, occurs certainly",
                    "qcode": "eocstat:eos5"
                }
            }
        ]
        """
        Then we get response code 201
        Then we store "EVENT" with 2 item
        When we get "/events"
        Then we get list with 3 items
        """
            {"_items": [
                {
                    "name": "Friday Club",
                    "dates": {"start": "2016-11-18T10:00:00+0000", "end": "2016-11-18T11:00:00+0000"}
                },
                {
                    "name": "Friday Club",
                    "dates": {"start": "2016-11-25T10:00:00+0000", "end": "2016-11-25T11:00:00+0000"}
                },
                {
                    "name": "Friday Club",
                    "dates": {"start": "2016-12-02T10:00:00+0000", "end": "2016-12-02T11:00:00+0000"}
                }
            ]}
        """
        When we patch "/events/#EVENT._id#"
        """
            {
                "name": "Friday Club changed",
                "dates": {
                    "start": "2016-12-10T14:00:00.000Z",
                    "end": "2016-12-10T15:00:00.000Z",
                    "tz": "Europe/Berlin",
                    "recurring_rule": {
                        "frequency": "WEEKLY",
                        "interval": 1,
                        "byday": "FR",
                        "count": 3,
                        "endRepeatMode": "count"
                    }
                }
            }
        """
        Then we get response code 200
        When we get "/events?source={"query":{"match":{"recurrence_id": "#EVENT.recurrence_id#"}}}"
        Then we get list with 4 items
        """
            {"_items": [{
                    "dates": {
                        "start": "2016-12-16T14:00:00+0000",
                        "end": "2016-12-16T15:00:00+0000"
                    },
                    "name": "Friday Club changed"
                }, {
                    "dates": {
                        "start": "2016-12-23T14:00:00+0000",
                        "end": "2016-12-23T15:00:00+0000"
                    },
                    "name": "Friday Club changed"
                }, {
                    "dates": {
                        "start": "2016-12-30T14:00:00+0000",
                        "end": "2016-12-30T15:00:00+0000"
                    },
                    "name": "Friday Club changed"
                }, {
                    "dates": {
                        "start": "2016-11-18T10:00:00+0000",
                        "end": "2016-11-18T11:00:00+0000"
                    },
                    "name": "Friday Club"
                }
           ]}
        """


 @auth
    @notification
    Scenario: Update a recurring event and delete some of following recurrences
         When we post to "events"
        """
        [
            {
                "unique_id": "123",
                "name": "Friday Club",
                "dates": {
                    "start": "2016-11-17T10:00:00.000Z",
                    "end": "2016-11-17T11:00:00.000Z",
                    "tz": "Europe/Berlin",
                    "recurring_rule": {
                        "frequency": "WEEKLY",
                        "interval": 1,
                        "byday": "FR",
                        "count": 5,
                        "endRepeatMode": "count"
                    }
                },
                "occur_status": {
                    "name": "Planned, occurs certainly",
                    "qcode": "eocstat:eos5"
                }
            }
        ]
        """
        Then we get response code 201
        Then we store "EVENT" with 2 item
        When we get "/events"
        Then we get list with 5 items
        """
            {"_items": [
                {
                    "name": "Friday Club",
                    "dates": {"start": "2016-11-18T10:00:00+0000", "end": "2016-11-18T11:00:00+0000"}
                },
                {
                    "name": "Friday Club",
                    "dates": {"start": "2016-11-25T10:00:00+0000", "end": "2016-11-25T11:00:00+0000"}
                },
                {
                    "name": "Friday Club",
                    "dates": {"start": "2016-12-02T10:00:00+0000", "end": "2016-12-02T11:00:00+0000"}
                },
                {
                    "name": "Friday Club",
                    "dates": {"start": "2016-12-09T10:00:00+0000", "end": "2016-12-09T11:00:00+0000"}
                },
                {
                    "name": "Friday Club",
                    "dates": {"start": "2016-12-16T10:00:00+0000", "end": "2016-12-16T11:00:00+0000"}
                }
            ]}
        """
        When we patch "/events/#EVENT._id#"
        """
            {
                "name": "Friday Club changed",
                "dates": {
                    "start": "2016-12-10T14:00:00.000Z",
                    "end": "2016-12-10T15:00:00.000Z",
                    "tz": "Europe/Berlin",
                    "recurring_rule": {
                        "frequency": "WEEKLY",
                        "interval": 1,
                        "byday": "FR",
                        "count": 2,
                        "endRepeatMode": "count"
                    }
                }
            }
        """
        Then we get response code 200
        When we get "/events?source={"query":{"match":{"recurrence_id": "#EVENT.recurrence_id#"}}}"
        Then we get list with 3 items
        """
            {"_items": [
                {
                    "dates": {
                        "end": "2016-11-18T11:00:00+0000",
                        "start": "2016-11-18T10:00:00+0000"
                    },
                    "name": "Friday Club"
                }, {
                    "dates": {
                        "end": "2016-12-16T15:00:00+0000",
                        "start": "2016-12-16T14:00:00+0000"
                    },
                    "name": "Friday Club changed"
                }, {
                    "dates": {
                        "end": "2016-12-23T15:00:00+0000",
                        "start": "2016-12-23T14:00:00+0000"
                    },
                    "name": "Friday Club changed"
                }
           ]}
        """
