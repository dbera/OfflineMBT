const testdata = {
    "graph": {
      "nodes": {
        "capuccino_selection": {
          "name": "capuccino_selection"
        },
        "espresso_was_delivered": {
          "name": "espresso_was_delivered"
        },
        "sugar_strength": {
          "name": "sugar_strength",
          "missing": [
            "Past"
          ]
        },
        "water_selection": {
          "name": "water_selection"
        },
        "milk_strength": {
          "name": "milk_strength",
          "missing": [
            "Past"
          ]
        },
        "water_was_delivered": {
          "name": "water_was_delivered"
        },
        "espresso_selection": {
          "name": "espresso_selection"
        },
        "coffee_strength": {
          "name": "coffee_strength",
          "missing": [
            "Past"
          ]
        },
        "ready": {
          "name": "ready",
          "missing": [
            "Past"
          ]
        },
        "capuccino_was_delivered": {
          "name": "capuccino_was_delivered"
        },
        "turn_on": {
          "name": "turn_on"
        }
      },
      "edges": [
        {
          "name": "ChSucc",
          "source": "ready",
          "target": "espresso_selection",
          "type": "both"
        },
        {
          "name": "with out \u003cb\u003eready \u003c/b\u003ein between",
          "source": "sugar_strength",
          "target": "espresso_was_delivered",
          "type": "dashedLeft"
        },
        {
          "name": "with out \u003cb\u003eready \u003c/b\u003ein between",
          "source": "coffee_strength",
          "target": "capuccino_was_delivered",
          "type": "dashedLeft"
        },
        {
          "name": "",
          "source": "turn_on",
          "target": "ready",
          "type": "right"
        },
        {
          "name": "ChSucc",
          "source": "ready",
          "target": "water_selection",
          "type": "both"
        },
        {
          "name": "with out \u003cb\u003eready \u003c/b\u003ein between",
          "source": "capuccino_selection",
          "target": "capuccino_was_delivered",
          "type": "dashedLeft"
        },
        {
          "name": "ChSucc",
          "source": "ready",
          "target": "capuccino_selection",
          "type": "both"
        },
        {
          "name": "with out \u003cb\u003eready \u003c/b\u003ein between",
          "source": "coffee_strength",
          "target": "espresso_was_delivered",
          "type": "dashedLeft"
        },
        {
          "name": "ChSucc",
          "source": "water_selection",
          "target": "water_was_delivered",
          "type": "both"
        },
        {
          "name": "with out \u003cb\u003eready \u003c/b\u003ein between",
          "source": "milk_strength",
          "target": "capuccino_was_delivered",
          "type": "dashedLeft"
        },
        {
          "name": "with out \u003cb\u003eready \u003c/b\u003ein between",
          "source": "espresso_selection",
          "target": "espresso_was_delivered",
          "type": "dashedLeft"
        },
        {
          "name": "with out \u003cb\u003eready \u003c/b\u003ein between",
          "source": "sugar_strength",
          "target": "capuccino_was_delivered",
          "type": "dashedLeft"
        }
      ]
    }
  }
export default testdata;