Feature: Duplicate Planning

    @auth @notification @wip
    Scenario: Duplicate a Planning item
        When we post to "planning" with success
        """
        [{
            "guid": "123",
            "headline": "test headline",
            "slugline": "test slugline",
            "state": "scheduled",
            "pubstatus": "usable",
            "planning_date": "2029-11-21T14:00:00.000Z"
        }]
        """
        When we patch "/planning/#planning._id#"
        """
        {
            "coverages": [
                {
                    "planning": {
                        "ednote": "test coverage, 250 words",
                        "headline": "test headline",
                        "slugline": "test slugline",
                        "scheduled": "2029-11-21T14:00:00.0000",
                        "g2_content_type": "text"
                    },
                    "workflow_status": "draft",
                    "assigned_to": {
                        "desk": "Politic Desk",
                        "user": "507f191e810c19729de870eb"
                    }
                }
            ]
        }
        """
        When we post to "/planning/123/duplicate"
        """
        [{}]
        """
        Then we get OK response
        When we get "/planning/123"
        Then we get existing resource
        """
        {
            "_id": "123",
            "guid": "123",
            "headline": "test headline",
            "slugline": "test slugline",
            "state": "scheduled",
            "pubstatus": "usable",
            "coverages": [
                {
                    "coverage_id": "__any_value__",
                    "planning": {
                        "ednote": "test coverage, 250 words",
                        "headline": "test headline",
                        "slugline": "test slugline",
                        "scheduled": "2029-11-21T14:00:00+0000",
                        "g2_content_type": "text"
                    },
                    "assigned_to": {
                        "desk": "Politic Desk",
                        "user": "507f191e810c19729de870eb",
                        "assignment_id": "__any_value__"
                    }
                }
            ]
        }
        """
        When we get "/planning/#duplicate._id#"
        Then we get existing resource
        """
        {
            "_id": "#duplicate._id#",
            "guid": "#duplicate._id#",
            "headline": "test headline",
            "slugline": "test slugline",
            "state": "draft",
            "pubstatus": "__no_value__",
            "coverages": [
                {
                    "planning": {
                        "ednote": "test coverage, 250 words",
                        "headline": "test headline",
                        "slugline": "test slugline",
                        "scheduled": "2029-11-21T14:00:00+0000",
                        "g2_content_type": "text"
                    },
                    "assigned_to": {}
                }
            ]
        }
        """
        When we get "/planning_history"
        Then we get list with 5 items
        """
        {"_items": [
            {
                "operation": "create",
                "planning_id": "123",
                "update": {
                    "headline": "test headline",
                    "slugline": "test slugline",
                    "state": "scheduled",
                    "pubstatus": "usable"
                }
            },
            {
                "operation": "post",
                "planning_id": "123"
            },
            {
                "operation": "coverage_created",
                "planning_id": "123",
                "update": {"coverage_id": "__any_value__"}
            },
            {
                "operation": "duplicate",
                "planning_id": "123",
                "update": {"duplicate_id": "#duplicate._id#"}
            },
            {
                "operation": "duplicate_from",
                "planning_id": "#duplicate._id#",
                "update": {
                    "duplicate_id": "123",
                    "headline": "test headline",
                    "slugline": "test slugline",
                    "state": "draft"
                }
            }
        ]}
        """
        And we get notifications
        """
        [
            {
                "event": "planning:created",
                "extra": {"item": "123"}
            },
            {
                "event": "planning:duplicated",
                "extra": {
                    "item": "#duplicate._id#",
                    "original": "123"
                }
            }
        ]
        """

    @auth
    Scenario: Planning can only be duplicated by user having privileges
        When we post to "planning" with success
        """
        [{
            "guid": "123",
            "headline": "test headline",
            "slugline": "test slugline",
            "state": "scheduled",
            "pubstatus": "usable",
            "planning_date": "2029-11-21T14:00:00.000Z"
        }]
        """
        When we patch "/users/#CONTEXT_USER_ID#"
        """
        {"user_type": "user", "privileges": {"planning_planning_management": 0, "users": 1}}
        """
        Then we get OK response
        When we post to "/planning/123/duplicate"
        """
        [{}]
        """
        Then we get error 403
        When we patch "/users/#CONTEXT_USER_ID#"
        """
        {"user_type": "user", "privileges": {"planning_planning_management": 1}}
        """
        Then we get OK response
        When we post to "/planning/123/duplicate"
        """
        [{}]
        """
        Then we get OK response


    @auth @notification
    Scenario: Coverage workflow_status defaults to draft on duplication item
        When we post to "planning" with success
        """
        [{
            "guid": "123",
            "headline": "test headline",
            "slugline": "test slugline",
            "state": "scheduled",
            "pubstatus": "usable",
            "planning_date": "2029-11-21T14:00:00.000Z"
        }]
        """
        When we patch "/planning/#planning._id#"
        """
        {
            "coverages": [
                {
                    "planning": {
                        "ednote": "test coverage, 250 words",
                        "headline": "test headline",
                        "slugline": "test slugline",
                        "scheduled": "2029-11-21T14:00:00.0000",
                        "g2_content_type": "text"
                    },
                    "assigned_to": {
                        "desk": "Politic Desk",
                        "user": "507f191e810c19729de870eb"
                    },
                    "workflow_status": "active"
                }
            ]
        }
        """
        When we post to "/planning/123/duplicate"
        """
        [{}]
        """
        Then we get OK response
        When we get "/planning/123"
        Then we get existing resource
        """
        {
            "_id": "123",
            "guid": "123",
            "headline": "test headline",
            "slugline": "test slugline",
            "state": "scheduled",
            "pubstatus": "usable",
            "coverages": [
                {
                    "coverage_id": "__any_value__",
                    "planning": {
                        "ednote": "test coverage, 250 words",
                        "headline": "test headline",
                        "slugline": "test slugline",
                        "scheduled": "2029-11-21T14:00:00+0000",
                        "g2_content_type": "text"
                    },
                    "assigned_to": {
                        "desk": "Politic Desk",
                        "user": "507f191e810c19729de870eb",
                        "assignment_id": "__any_value__"
                    },
                    "workflow_status": "active"
                }
            ]
        }
        """
        When we get "/planning/#duplicate._id#"
        Then we get existing resource
        """
        {
            "_id": "#duplicate._id#",
            "guid": "#duplicate._id#",
            "headline": "test headline",
            "slugline": "test slugline",
            "state": "draft",
            "pubstatus": "__no_value__",
            "coverages": [
                {
                    "planning": {
                        "ednote": "test coverage, 250 words",
                        "headline": "test headline",
                        "slugline": "test slugline",
                        "scheduled": "2029-11-21T14:00:00+0000",
                        "g2_content_type": "text"
                    },
                    "assigned_to": {},
                    "workflow_status": "draft"
                }
            ]
        }
        """

    @auth @notification @wip @newtest
    Scenario: Duplicating a posted Planning item won't repost it
        When we post to "planning" with success
        """
        [{
            "guid": "123",
            "headline": "test headline",
            "slugline": "test slugline",
            "planning_date": "2029-11-21T14:00:00.000Z"
        }]
        """
        Then we get OK response
        When we post to "/planning/post"
        """
        {
            "planning": "#planning._id#",
            "etag": "#planning._etag#",
            "pubstatus": "usable"
        }
        """
        Then we get OK response
        When we post to "/planning/123/duplicate"
        """
        [{}]
        """
        Then we get OK response
        When we get "/planning_history"
        Then we get list with 4 items
        """
        {"_items": [
            {
                "operation": "create",
                "planning_id": "123",
                "update": {
                    "headline": "test headline",
                    "slugline": "test slugline"
                }
            },
            {
                "operation": "post",
                "planning_id": "123"
            },
            {
                "operation": "duplicate",
                "planning_id": "123",
                "update": {"duplicate_id": "#duplicate._id#"}
            },
            {
                "operation": "duplicate_from",
                "planning_id": "#duplicate._id#"
            }
        ]}
        """

    @auth
    Scenario: Duplicate a past planning item will have current date
        Given "planning"
        """
        [{
            "_id": "plan1",
            "guid": "plan1",
            "slugline": "TestPlan",
            "state": "draft",
            "planning_date": "2012-11-21T14:00:00.000Z",
            "coverages": [{
                "coverage_id": "cov1",
                "slugline": "TestCoverage 1",
                "planning": {
                    "internal_note": "Cover something please!",
                    "scheduled": "2012-11-21T14:00:00.000Z"
                },
                "planning_item": "plan1",
                "news_coverage_status": {
                    "qcode": "ncostat:int",
                    "name": "Coverage intended"
                },
                "assigned_to": {
                    "desk": "#desks._id#",
                    "user": "#CONTEXT_USER_ID#",
                    "assignment_id": "aaaaaaaaaaaaaaaaaaaaaaaa"
                }
            }],
            "expired": true

        }]
        """
        When we post to "/planning/plan1/duplicate"
        """
        [{}]
        """
        Then we get OK response
        When we get "/planning/#duplicate._id#"
        Then planning item has current date
        Then coverage 0 has current date
        Then we get existing resource
        """
        {"expired": "__no_value__"}
        """

    @auth
    Scenario: Duplicating a Planning item will link to the same Event
        Given "events"
        """
        [{
            "_id": "event1",
            "guid": "event1",
            "name": "Test Event",
            "dates": {
                "start": "2029-11-21T12:00:00.000Z",
                "end": "2029-11-21T14:00:00.000Z",
                "tz": "Australia/Sydney"
            },
            "state": "draft"
        }]
        """
        Given "planning"
        """
        [{
            "_id": "plan1",
            "guid": "plan1",
            "slugline": "Test Event",
            "state": "draft",
            "event_item": "event1",
            "planning_date": "2029-11-21T14:00:00.000Z"
        }]
        """
        When we post to "/planning/plan1/duplicate"
        """
        [{}]
        """
        Then we get OK response
        When we get "/planning/#duplicate._id#"
        Then we get existing resource
        """
        {
            "_id": "#duplicate._id#",
            "guid": "#duplicate._id#",
            "slugline": "Test Event",
            "state": "draft",
            "planning_date": "2029-11-21T14:00:00+0000",
            "event_item": "event1",
            "expired": "__no_value__"
        }
        """

    @auth
    Scenario: Duplicating an expired Planning item will remove the link to the Event
        Given "events"
        """
        [{
            "_id": "event1",
            "guid": "event1",
            "name": "Test Event",
            "dates": {
                "start": "2029-11-21T12:00:00.000Z",
                "end": "2029-11-21T14:00:00.000Z",
                "tz": "Australia/Sydney"
            },
            "state": "draft",
            "expired": true
        }]
        """
        Given "planning"
        """
        [{
            "_id": "plan1",
            "guid": "plan1",
            "slugline": "Test Event",
            "state": "draft",
            "event_item": "event1",
            "planning_date": "2029-11-21T14:00:00.000Z",
            "expired": true
        }]
        """
        When we post to "/planning/plan1/duplicate"
        """
        [{}]
        """
        Then we get OK response
        When we get "/planning/#duplicate._id#"
        Then we get existing resource
        """
        {
            "_id": "#duplicate._id#",
            "guid": "#duplicate._id#",
            "slugline": "Test Event",
            "state": "draft",
            "planning_date": "2029-11-21T14:00:00+0000",
            "event_item": "__no_value__",
            "expired": "__no_value__"
        }
        """

    @auth
    Scenario: Duplicating a canceled Planning item will clear the ednote
        Given "events"
        """
        [{
            "_id": "event1",
            "guid": "event1",
            "name": "Test Event",
            "ednote" : "Ed note in event\n\n--------------------------------------------\nEvent Cancelled\nReason: \n",
            "dates": {
                "start": "2029-11-21T12:00:00.000Z",
                "end": "2029-11-21T14:00:00.000Z",
                "tz": "Australia/Sydney"
            },
            "state" : "cancelled"
        }]
        """
        Given "planning"
        """
        [{
            "_id": "plan1",
            "guid": "plan1",
            "slugline": "Test Event",
            "state" : "cancelled",
            "event_item": "event1",
            "planning_date": "2029-11-21T14:00:00.000Z",
            "ednote" : "This is the ednote in planning\n\n-----------------------------------------\nEvent cancelled\n",
            "coverages": [
                {
                    "planning": {
                        "ednote": "test coverage, 250 words",
                        "headline": "test headline",
                        "slugline": "test slugline",
                        "scheduled": "2029-11-21T14:00:00.0000",
                        "g2_content_type": "text",
                        "ednote" : "This is the ednote in planning\n\n-------------\nCoverage cancelled\nReason: bad\n"
                    },
                    "workflow_status": "cancelled",
                    "assigned_to": {
                        "desk": "Politic Desk",
                        "user": "507f191e810c19729de870eb"
                    }
                }
            ]
        }]
        """
        When we post to "/planning/plan1/duplicate"
        """
        [{}]
        """
        Then we get OK response
        When we get "/planning/#duplicate._id#"
        Then we get existing resource
        """
        {
            "_id": "#duplicate._id#",
            "guid": "#duplicate._id#",
            "slugline": "Test Event",
            "state": "draft",
            "planning_date": "2029-11-21T14:00:00+0000",
            "event_item": "event1",
            "expired": "__no_value__",
            "ednote": "__no_value__",
            "coverages": [{"planning": {"ednote": "__no_value__"}}]
        }
        """