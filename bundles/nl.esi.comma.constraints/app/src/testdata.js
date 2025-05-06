/*
 * Copyright (c) 2024, 2025 TNO-ESI
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available
 * under the terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT
 *
 * SPDX-License-Identifier: MIT
 */

const conformanceCheckingReport = {
	"meta": {
	  "createdAt": "2021-10-12T12:20:43.452"
	},
  "conformanceResults": [
    {
      "constraintName": "ClinicalWorkflow_of_3DRA",
      "constraintText": [],
      "constraintDot": "",
      "numberOfConformingSCN": 0,
      "testCoverage": 0.0,
      "stateCoverage": 0.0,
      "transitionCoverage": 0.0,
      "listOfConformingScenarios": [],
      "listOfViolatingScenarios": []
    },
    {
      "constraintName": "ClinicalWorkflow_of_ABDOMEN_CBCT_DUAL",
      "constraintText": [],
      "constraintDot": "",
      "numberOfConformingSCN": 0,
      "testCoverage": 0.0,
      "stateCoverage": 0.0,
      "transitionCoverage": 0.0,
      "listOfConformingScenarios": [],
      "listOfViolatingScenarios": []
    },
    {
      "constraintName": "ClinicalWorkflow_of_Cone_Beam_CT",
      "constraintText": [],
      "constraintDot": "",
      "numberOfConformingSCN": 0,
      "testCoverage": 0.0,
      "stateCoverage": 0.0,
      "transitionCoverage": 0.0,
      "listOfConformingScenarios": [],
      "listOfViolatingScenarios": []
    },
    {
      "constraintName": "ClinicalWorkflow_of_CBCT",
      "constraintText": [],
      "constraintDot": "",
      "numberOfConformingSCN": 0,
      "testCoverage": 0.0,
      "stateCoverage": 0.0,
      "transitionCoverage": 0.0,
      "listOfConformingScenarios": [],
      "listOfViolatingScenarios": []
    },
    {
      "constraintName": "ClinicalWorkflow_of_VASO_CT",
      "constraintText": [],
      "constraintDot": "",
      "numberOfConformingSCN": 0,
      "testCoverage": 0.0,
      "stateCoverage": 0.0,
      "transitionCoverage": 0.0,
      "listOfConformingScenarios": [],
      "listOfViolatingScenarios": []
    }
  ],
  "testGenerations": [
    {
      "constraintName": "ClinicalWorkflow_of_VASO_CT",
      "constraintText": [
        "> if default main view is Coronal in the layout occurs then define vessel in coronal, quick measurements in coronal view, add landmark in coronal and 3d viewports and zoom, activate cropping tool and remove skull, freeform cut, define lesion in coronal 2d, slab interaction in axial view from coronal, store five angles in planning task must immediately-follow",
        "<> if activate cropping tool and remove skull then navigate to series segementation and disable skull removal must-immediately-follow, and vice-versa",
        "<> if freeform cut then undo and redo freeform cut must-immediately-follow, and vice-versa",
        "<- whenever activate cropping tool and remove skull, freeform cut, define lesion in coronal 2d, add landmark in coronal and 3d viewports and zoom, store five angles in planning task occurs then define vessel in coronal, quick measurements in coronal view, slab interaction in axial view from coronal must have-occurred-before",
        "<- whenever store five angles in planning task, store current angle roll and store again in planning task, navigate to series task and create new recon with stent opt occurs then define vessel in coronal, quick measurements in coronal view, add landmark in coronal and 3d viewports and zoom, activate cropping tool and remove skull, freeform cut, define lesion in coronal 2d, slab interaction in axial view from coronal must have-occurred-before",
        "< whenever create and store fluro run head coronary in live task occurs then store current angle roll and store again in planning task must have-occurred-immediately-before",
        "<> if store five angles in planning task then recall third run and create and store fluro head vaso ct must-immediately-follow, and vice-versa",
        "<> if exposure run and launch smartCT with epx head vaso ct 27 10 5 man 4s then default main view is Coronal in the layout must-immediately-follow, and vice-versa",
        "define vessel in coronal, quick measurements in coronal view, add landmark in coronal and 3d viewports and zoom, activate cropping tool and remove skull, freeform cut, define lesion in coronal 2d, store five angles in planning task, store current angle roll and store again in planning task, navigate to series task and create new recon with stent opt, slab interaction in axial view from coronal, store five angles in planning task occurs-at-most 1 times",
        "exposure run and launch smartCT with epx head vaso ct 27 10 5 man 4s occurs-first",
        "create and store fluro run head coronary in live task, exposure run and launch smartCT with epx head vaso ct 27 10 5 man 4s occurs-at-most 1 times",
        "create and store fluro run head coronary in live task, navigate to series task and create new recon with stent opt, recall third run and create and store fluro head vaso ct occurs-last"
      ],
      "constraintDot": "ZGlncmFwaCBBdXRvbWF0b24gewogIHJhbmtkaXIgPSBMUjsKICAwIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDAgLT4gNjEgW2xhYmVsPSJ1bmRvX2FuZF9yZWRvX2ZyZWVmb3JtX2N1dCJdCiAgMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxIC0+IDQ0IFtsYWJlbD0icmVjYWxsX3RoaXJkX3J1bl9hbmRfY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19oZWFkX3Zhc29fY3QiXQogIDIgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMiAtPiAyIFtsYWJlbD0iQU5ZIl0KICAyIC0+IDQyIFtsYWJlbD0iZGVmaW5lX2xlc2lvbl9pbl9jb3JvbmFsXzJkIl0KICAzIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDMgLT4gNTQgW2xhYmVsPSJyZWNhbGxfdGhpcmRfcnVuX2FuZF9jcmVhdGVfYW5kX3N0b3JlX2ZsdXJvX2hlYWRfdmFzb19jdCJdCiAgNCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA0IC0+IDYwIFtsYWJlbD0iYWN0aXZhdGVfY3JvcHBpbmdfdG9vbF9hbmRfcmVtb3ZlX3NrdWxsIl0KICA0IC0+IDQ4IFtsYWJlbD0iZnJlZWZvcm1fY3V0Il0KICA0IC0+IDQgW2xhYmVsPSJBTlkiXQogIDUgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNSAtPiA0NSBbbGFiZWw9ImZyZWVmb3JtX2N1dCJdCiAgNSAtPiA1IFtsYWJlbD0iQU5ZIl0KICA1IC0+IDMzIFtsYWJlbD0iZGVmaW5lX2xlc2lvbl9pbl9jb3JvbmFsXzJkIl0KICA2IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDYgLT4gNSBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc19zZWdlbWVudGF0aW9uX2FuZF9kaXNhYmxlX3NrdWxsX3JlbW92YWwiXQogIDcgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNyAtPiA1MCBbbGFiZWw9ImRlZmluZV92ZXNzZWxfaW5fY29yb25hbCJdCiAgNyAtPiA3IFtsYWJlbD0iQU5ZIl0KICA4IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDggLT4gMzggW2xhYmVsPSJuYXZpZ2F0ZV90b19zZXJpZXNfc2VnZW1lbnRhdGlvbl9hbmRfZGlzYWJsZV9za3VsbF9yZW1vdmFsIl0KICA5IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDkgLT4gMjcgW2xhYmVsPSJkZWZpbmVfdmVzc2VsX2luX2Nvcm9uYWwiXQogIDkgLT4gNyBbbGFiZWw9InF1aWNrX21lYXN1cmVtZW50c19pbl9jb3JvbmFsX3ZpZXciXQogIDkgLT4gOSBbbGFiZWw9IkFOWSJdCiAgMTAgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMTAgLT4gNiBbbGFiZWw9ImFjdGl2YXRlX2Nyb3BwaW5nX3Rvb2xfYW5kX3JlbW92ZV9za3VsbCJdCiAgMTAgLT4gMTQgW2xhYmVsPSJmcmVlZm9ybV9jdXQiXQogIDEwIC0+IDEwIFtsYWJlbD0iQU5ZIl0KICAxMCAtPiA0IFtsYWJlbD0iZGVmaW5lX2xlc2lvbl9pbl9jb3JvbmFsXzJkIl0KICAxMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxMSAtPiA0MSBbbGFiZWw9InJlY2FsbF90aGlyZF9ydW5fYW5kX2NyZWF0ZV9hbmRfc3RvcmVfZmx1cm9faGVhZF92YXNvX2N0Il0KICAxMiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxMiAtPiAyNCBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDEyIC0+IDM0IFtsYWJlbD0ic3RvcmVfY3VycmVudF9hbmdsZV9yb2xsX2FuZF9zdG9yZV9hZ2Fpbl9pbl9wbGFubmluZ190YXNrIl0KICAxMiAtPiAxMiBbbGFiZWw9IkFOWSJdCiAgMTMgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMTMgLT4gNTkgW2xhYmVsPSJfZGVmYXVsdF9tYWluX3ZpZXdfaXNfQ29yb25hbF9pbl90aGVfbGF5b3V0XyJdCiAgMTQgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMTQgLT4gMTcgW2xhYmVsPSJ1bmRvX2FuZF9yZWRvX2ZyZWVmb3JtX2N1dCJdCiAgMTUgW3NoYXBlPWRvdWJsZWNpcmNsZSxsYWJlbD0iIl07CiAgMTUgLT4gMSBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDE1IC0+IDUzIFtsYWJlbD0iQU5ZIl0KICAxNSAtPiA1NyBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc190YXNrX2FuZF9jcmVhdGVfbmV3X3JlY29uX3dpdGhfc3RlbnRfb3B0Il0KICAxNiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxNiAtPiA0MiBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc19zZWdlbWVudGF0aW9uX2FuZF9kaXNhYmxlX3NrdWxsX3JlbW92YWwiXQogIDE3IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE3IC0+IDUxIFtsYWJlbD0iYWN0aXZhdGVfY3JvcHBpbmdfdG9vbF9hbmRfcmVtb3ZlX3NrdWxsIl0KICAxNyAtPiAxNyBbbGFiZWw9IkFOWSJdCiAgMTcgLT4gMzUgW2xhYmVsPSJkZWZpbmVfbGVzaW9uX2luX2Nvcm9uYWxfMmQiXQogIDE4IFtzaGFwZT1kb3VibGVjaXJjbGUsbGFiZWw9IiJdOwogIDE5IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE5IC0+IDQ0IFtsYWJlbD0iY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19ydW5faGVhZF9jb3JvbmFyeV9pbl9saXZlX3Rhc2siXQogIDE5IC0+IDE4IFtsYWJlbD0ibmF2aWdhdGVfdG9fc2VyaWVzX3Rhc2tfYW5kX2NyZWF0ZV9uZXdfcmVjb25fd2l0aF9zdGVudF9vcHQiXQogIDE5IC0+IDI1IFtsYWJlbD0iQU5ZIl0KICAyMCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyMCAtPiAyMCBbbGFiZWw9IkFOWSJdCiAgMjAgLT4gNDkgW2xhYmVsPSJuYXZpZ2F0ZV90b19zZXJpZXNfdGFza19hbmRfY3JlYXRlX25ld19yZWNvbl93aXRoX3N0ZW50X29wdCJdCiAgMjEgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjEgLT4gMTUgW2xhYmVsPSJjcmVhdGVfYW5kX3N0b3JlX2ZsdXJvX3J1bl9oZWFkX2Nvcm9uYXJ5X2luX2xpdmVfdGFzayJdCiAgMjEgLT4gMyBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDIxIC0+IDQ3IFtsYWJlbD0ibmF2aWdhdGVfdG9fc2VyaWVzX3Rhc2tfYW5kX2NyZWF0ZV9uZXdfcmVjb25fd2l0aF9zdGVudF9vcHQiXQogIDIxIC0+IDU2IFtsYWJlbD0iQU5ZIl0KICAyMiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyMiAtPiA2OCBbbGFiZWw9ImZyZWVmb3JtX2N1dCJdCiAgMjIgLT4gMjIgW2xhYmVsPSJBTlkiXQogIDIyIC0+IDMzIFtsYWJlbD0iYWRkX2xhbmRtYXJrX2luX2Nvcm9uYWxfYW5kXzNkX3ZpZXdwb3J0c19hbmRfem9vbSJdCiAgMjMgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjMgLT4gMTkgW2xhYmVsPSJzdG9yZV9jdXJyZW50X2FuZ2xlX3JvbGxfYW5kX3N0b3JlX2FnYWluX2luX3BsYW5uaW5nX3Rhc2siXQogIDIzIC0+IDIzIFtsYWJlbD0iQU5ZIl0KICAyMyAtPiA0MyBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc190YXNrX2FuZF9jcmVhdGVfbmV3X3JlY29uX3dpdGhfc3RlbnRfb3B0Il0KICAyNCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyNCAtPiA0MyBbbGFiZWw9InJlY2FsbF90aGlyZF9ydW5fYW5kX2NyZWF0ZV9hbmRfc3RvcmVfZmx1cm9faGVhZF92YXNvX2N0Il0KICAyNSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyNSAtPiAxOCBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc190YXNrX2FuZF9jcmVhdGVfbmV3X3JlY29uX3dpdGhfc3RlbnRfb3B0Il0KICAyNSAtPiAyNSBbbGFiZWw9IkFOWSJdCiAgMjYgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjYgLT4gMjYgW2xhYmVsPSJBTlkiXQogIDI2IC0+IDQyIFtsYWJlbD0iYWRkX2xhbmRtYXJrX2luX2Nvcm9uYWxfYW5kXzNkX3ZpZXdwb3J0c19hbmRfem9vbSJdCiAgMjcgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjcgLT4gNTAgW2xhYmVsPSJxdWlja19tZWFzdXJlbWVudHNfaW5fY29yb25hbF92aWV3Il0KICAyNyAtPiAyNyBbbGFiZWw9IkFOWSJdCiAgMjggW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjggLT4gNjYgW2xhYmVsPSJ1bmRvX2FuZF9yZWRvX2ZyZWVmb3JtX2N1dCJdCiAgMjkgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjkgLT4gNjEgW2xhYmVsPSJuYXZpZ2F0ZV90b19zZXJpZXNfc2VnZW1lbnRhdGlvbl9hbmRfZGlzYWJsZV9za3VsbF9yZW1vdmFsIl0KICAzMCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzMCAtPiA0NiBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDMwIC0+IDMwIFtsYWJlbD0iQU5ZIl0KICAzMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzMSAtPiA3IFtsYWJlbD0ic2xhYl9pbnRlcmFjdGlvbl9pbl9heGlhbF92aWV3X2Zyb21fY29yb25hbCJdCiAgMzEgLT4gMzIgW2xhYmVsPSJkZWZpbmVfdmVzc2VsX2luX2Nvcm9uYWwiXQogIDMxIC0+IDMxIFtsYWJlbD0iQU5ZIl0KICAzMiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzMiAtPiA1MCBbbGFiZWw9InNsYWJfaW50ZXJhY3Rpb25faW5fYXhpYWxfdmlld19mcm9tX2Nvcm9uYWwiXQogIDMyIC0+IDMyIFtsYWJlbD0iQU5ZIl0KICAzMyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzMyAtPiA2NSBbbGFiZWw9ImZyZWVmb3JtX2N1dCJdCiAgMzMgLT4gMzMgW2xhYmVsPSJBTlkiXQogIDM0IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDM0IC0+IDU3IFtsYWJlbD0iY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19ydW5faGVhZF9jb3JvbmFyeV9pbl9saXZlX3Rhc2siXQogIDM0IC0+IDQ2IFtsYWJlbD0ic3RvcmVfZml2ZV9hbmdsZXNfaW5fcGxhbm5pbmdfdGFzayJdCiAgMzQgLT4gMzAgW2xhYmVsPSJBTlkiXQogIDM1IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDM1IC0+IDE2IFtsYWJlbD0iYWN0aXZhdGVfY3JvcHBpbmdfdG9vbF9hbmRfcmVtb3ZlX3NrdWxsIl0KICAzNSAtPiAzNSBbbGFiZWw9IkFOWSJdCiAgMzYgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMzYgLT4gMjcgW2xhYmVsPSJzbGFiX2ludGVyYWN0aW9uX2luX2F4aWFsX3ZpZXdfZnJvbV9jb3JvbmFsIl0KICAzNiAtPiAzMiBbbGFiZWw9InF1aWNrX21lYXN1cmVtZW50c19pbl9jb3JvbmFsX3ZpZXciXQogIDM2IC0+IDM2IFtsYWJlbD0iQU5ZIl0KICAzNyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzNyAtPiA2MyBbbGFiZWw9InVuZG9fYW5kX3JlZG9fZnJlZWZvcm1fY3V0Il0KICAzOCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzOCAtPiAwIFtsYWJlbD0iZnJlZWZvcm1fY3V0Il0KICAzOCAtPiAzOCBbbGFiZWw9IkFOWSJdCiAgMzggLT4gMjIgW2xhYmVsPSJkZWZpbmVfbGVzaW9uX2luX2Nvcm9uYWxfMmQiXQogIDM4IC0+IDUgW2xhYmVsPSJhZGRfbGFuZG1hcmtfaW5fY29yb25hbF9hbmRfM2Rfdmlld3BvcnRzX2FuZF96b29tIl0KICAzOSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzOSAtPiA0OSBbbGFiZWw9ImNyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2hlYWRfY29yb25hcnlfaW5fbGl2ZV90YXNrIl0KICA0MCBbc2hhcGU9ZG91YmxlY2lyY2xlLGxhYmVsPSIiXTsKICA0MCAtPiAyNCBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDQwIC0+IDM0IFtsYWJlbD0ic3RvcmVfY3VycmVudF9hbmdsZV9yb2xsX2FuZF9zdG9yZV9hZ2Fpbl9pbl9wbGFubmluZ190YXNrIl0KICA0MCAtPiAxMiBbbGFiZWw9IkFOWSJdCiAgNDEgW3NoYXBlPWRvdWJsZWNpcmNsZSxsYWJlbD0iIl07CiAgNDEgLT4gMTkgW2xhYmVsPSJzdG9yZV9jdXJyZW50X2FuZ2xlX3JvbGxfYW5kX3N0b3JlX2FnYWluX2luX3BsYW5uaW5nX3Rhc2siXQogIDQxIC0+IDIzIFtsYWJlbD0iQU5ZIl0KICA0MSAtPiA0MyBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc190YXNrX2FuZF9jcmVhdGVfbmV3X3JlY29uX3dpdGhfc3RlbnRfb3B0Il0KICA0MiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA0MiAtPiAxMSBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDQyIC0+IDIxIFtsYWJlbD0ic3RvcmVfY3VycmVudF9hbmdsZV9yb2xsX2FuZF9zdG9yZV9hZ2Fpbl9pbl9wbGFubmluZ190YXNrIl0KICA0MiAtPiA0MCBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc190YXNrX2FuZF9jcmVhdGVfbmV3X3JlY29uX3dpdGhfc3RlbnRfb3B0Il0KICA0MiAtPiA0MiBbbGFiZWw9IkFOWSJdCiAgNDMgW3NoYXBlPWRvdWJsZWNpcmNsZSxsYWJlbD0iIl07CiAgNDMgLT4gMzkgW2xhYmVsPSJzdG9yZV9jdXJyZW50X2FuZ2xlX3JvbGxfYW5kX3N0b3JlX2FnYWluX2luX3BsYW5uaW5nX3Rhc2siXQogIDQzIC0+IDU4IFtsYWJlbD0iQU5ZIl0KICA0NCBbc2hhcGU9ZG91YmxlY2lyY2xlLGxhYmVsPSIiXTsKICA0NCAtPiAyMCBbbGFiZWw9IkFOWSJdCiAgNDQgLT4gNDkgW2xhYmVsPSJuYXZpZ2F0ZV90b19zZXJpZXNfdGFza19hbmRfY3JlYXRlX25ld19yZWNvbl93aXRoX3N0ZW50X29wdCJdCiAgNDUgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNDUgLT4gMiBbbGFiZWw9InVuZG9fYW5kX3JlZG9fZnJlZWZvcm1fY3V0Il0KICA0NiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA0NiAtPiAxOCBbbGFiZWw9InJlY2FsbF90aGlyZF9ydW5fYW5kX2NyZWF0ZV9hbmRfc3RvcmVfZmx1cm9faGVhZF92YXNvX2N0Il0KICA0NyBbc2hhcGU9ZG91YmxlY2lyY2xlLGxhYmVsPSIiXTsKICA0NyAtPiA0NiBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDQ3IC0+IDMwIFtsYWJlbD0iQU5ZIl0KICA0OCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA0OCAtPiAzNSBbbGFiZWw9InVuZG9fYW5kX3JlZG9fZnJlZWZvcm1fY3V0Il0KICA0OSBbc2hhcGU9ZG91YmxlY2lyY2xlLGxhYmVsPSIiXTsKICA1MCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA1MCAtPiA4IFtsYWJlbD0iYWN0aXZhdGVfY3JvcHBpbmdfdG9vbF9hbmRfcmVtb3ZlX3NrdWxsIl0KICA1MCAtPiAzNyBbbGFiZWw9ImZyZWVmb3JtX2N1dCJdCiAgNTAgLT4gNTAgW2xhYmVsPSJBTlkiXQogIDUwIC0+IDUyIFtsYWJlbD0iZGVmaW5lX2xlc2lvbl9pbl9jb3JvbmFsXzJkIl0KICA1MCAtPiAxMCBbbGFiZWw9ImFkZF9sYW5kbWFya19pbl9jb3JvbmFsX2FuZF8zZF92aWV3cG9ydHNfYW5kX3pvb20iXQogIDUxIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDUxIC0+IDIgW2xhYmVsPSJuYXZpZ2F0ZV90b19zZXJpZXNfc2VnZW1lbnRhdGlvbl9hbmRfZGlzYWJsZV9za3VsbF9yZW1vdmFsIl0KICA1MiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA1MiAtPiA2NCBbbGFiZWw9ImFjdGl2YXRlX2Nyb3BwaW5nX3Rvb2xfYW5kX3JlbW92ZV9za3VsbCJdCiAgNTIgLT4gMjggW2xhYmVsPSJmcmVlZm9ybV9jdXQiXQogIDUyIC0+IDUyIFtsYWJlbD0iQU5ZIl0KICA1MiAtPiA0IFtsYWJlbD0iYWRkX2xhbmRtYXJrX2luX2Nvcm9uYWxfYW5kXzNkX3ZpZXdwb3J0c19hbmRfem9vbSJdCiAgNTMgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNTMgLT4gMSBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDUzIC0+IDUzIFtsYWJlbD0iQU5ZIl0KICA1MyAtPiA1NyBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc190YXNrX2FuZF9jcmVhdGVfbmV3X3JlY29uX3dpdGhfc3RlbnRfb3B0Il0KICA1NCBbc2hhcGU9ZG91YmxlY2lyY2xlLGxhYmVsPSIiXTsKICA1NCAtPiAxOCBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc190YXNrX2FuZF9jcmVhdGVfbmV3X3JlY29uX3dpdGhfc3RlbnRfb3B0Il0KICA1NCAtPiAyNSBbbGFiZWw9IkFOWSJdCiAgNTUgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgaW5pdGlhbCBbc2hhcGU9cGxhaW50ZXh0LGxhYmVsPSIiXTsKICBpbml0aWFsIC0+IDU1CiAgNTUgLT4gMTMgW2xhYmVsPSJleHBvc3VyZV9ydW5fYW5kX2xhdW5jaF9zbWFydENUX3dpdGhfZXB4X2hlYWRfdmFzb19jdF8yN18xMF81X21hbl80cyJdCiAgNTYgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNTYgLT4gMyBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDU2IC0+IDQ3IFtsYWJlbD0ibmF2aWdhdGVfdG9fc2VyaWVzX3Rhc2tfYW5kX2NyZWF0ZV9uZXdfcmVjb25fd2l0aF9zdGVudF9vcHQiXQogIDU2IC0+IDU2IFtsYWJlbD0iQU5ZIl0KICA1NyBbc2hhcGU9ZG91YmxlY2lyY2xlLGxhYmVsPSIiXTsKICA1NyAtPiA2OSBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDU3IC0+IDY3IFtsYWJlbD0iQU5ZIl0KICA1OCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA1OCAtPiAzOSBbbGFiZWw9InN0b3JlX2N1cnJlbnRfYW5nbGVfcm9sbF9hbmRfc3RvcmVfYWdhaW5faW5fcGxhbm5pbmdfdGFzayJdCiAgNTggLT4gNTggW2xhYmVsPSJBTlkiXQogIDU5IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDU5IC0+IDkgW2xhYmVsPSJzbGFiX2ludGVyYWN0aW9uX2luX2F4aWFsX3ZpZXdfZnJvbV9jb3JvbmFsIl0KICA1OSAtPiAzNiBbbGFiZWw9ImRlZmluZV92ZXNzZWxfaW5fY29yb25hbCJdCiAgNTkgLT4gMzEgW2xhYmVsPSJxdWlja19tZWFzdXJlbWVudHNfaW5fY29yb25hbF92aWV3Il0KICA2MCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA2MCAtPiAzMyBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc19zZWdlbWVudGF0aW9uX2FuZF9kaXNhYmxlX3NrdWxsX3JlbW92YWwiXQogIDYxIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDYxIC0+IDYxIFtsYWJlbD0iQU5ZIl0KICA2MSAtPiAyNiBbbGFiZWw9ImRlZmluZV9sZXNpb25faW5fY29yb25hbF8yZCJdCiAgNjEgLT4gMiBbbGFiZWw9ImFkZF9sYW5kbWFya19pbl9jb3JvbmFsX2FuZF8zZF92aWV3cG9ydHNfYW5kX3pvb20iXQogIDYyIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDYyIC0+IDI2IFtsYWJlbD0ibmF2aWdhdGVfdG9fc2VyaWVzX3NlZ2VtZW50YXRpb25fYW5kX2Rpc2FibGVfc2t1bGxfcmVtb3ZhbCJdCiAgNjMgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNjMgLT4gMjkgW2xhYmVsPSJhY3RpdmF0ZV9jcm9wcGluZ190b29sX2FuZF9yZW1vdmVfc2t1bGwiXQogIDYzIC0+IDYzIFtsYWJlbD0iQU5ZIl0KICA2MyAtPiA2NiBbbGFiZWw9ImRlZmluZV9sZXNpb25faW5fY29yb25hbF8yZCJdCiAgNjMgLT4gMTcgW2xhYmVsPSJhZGRfbGFuZG1hcmtfaW5fY29yb25hbF9hbmRfM2Rfdmlld3BvcnRzX2FuZF96b29tIl0KICA2NCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA2NCAtPiAyMiBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc19zZWdlbWVudGF0aW9uX2FuZF9kaXNhYmxlX3NrdWxsX3JlbW92YWwiXQogIDY1IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDY1IC0+IDQyIFtsYWJlbD0idW5kb19hbmRfcmVkb19mcmVlZm9ybV9jdXQiXQogIDY2IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDY2IC0+IDYyIFtsYWJlbD0iYWN0aXZhdGVfY3JvcHBpbmdfdG9vbF9hbmRfcmVtb3ZlX3NrdWxsIl0KICA2NiAtPiA2NiBbbGFiZWw9IkFOWSJdCiAgNjYgLT4gMzUgW2xhYmVsPSJhZGRfbGFuZG1hcmtfaW5fY29yb25hbF9hbmRfM2Rfdmlld3BvcnRzX2FuZF96b29tIl0KICA2NyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA2NyAtPiA2OSBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDY3IC0+IDY3IFtsYWJlbD0iQU5ZIl0KICA2OCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA2OCAtPiAyNiBbbGFiZWw9InVuZG9fYW5kX3JlZG9fZnJlZWZvcm1fY3V0Il0KICA2OSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA2OSAtPiA0OSBbbGFiZWw9InJlY2FsbF90aGlyZF9ydW5fYW5kX2NyZWF0ZV9hbmRfc3RvcmVfZmx1cm9faGVhZF92YXNvX2N0Il0KfQo=",
      "configurations": [],
      "featureFileLocation": "ClinicalWorkflow_of_VASO_CT.feature",
      "statistics": {
        "algorithm": "DFS",
        "amountOfStatesInAutomaton": 70,
        "amountOfTransitionsInAutomaton": 145,
        "amountOfTransitionsCoveredByExistingScenarios": 0,
        "amountOfPaths": 32,
        "amountOfSteps": 415,
        "percentageTransitionsCoveredByExistingScenarios": 0.0,
        "averageAmountOfStepsPerSequence": 12.96875,
        "percentageOfStatesCovered": 0.8714285714285714,
        "percentageOfTransitionsCovered": 0.6206896551724138,
        "averageTransitionExecution": 4.611111111111111,
        "timesTransitionIsExecuted": {
          "32": [
            "_default_main_view_is_Coronal_in_the_layout_",
            "exposure_run_and_launch_smartCT_with_epx_head_vaso_ct_27_10_5_man_4s"
          ],
          "16": [
            "undo_and_redo_freeform_cut",
            "freeform_cut",
            "define_lesion_in_coronal_2d"
          ],
          "1": [
            "navigate_to_series_task_and_create_new_recon_with_stent_opt",
            "define_lesion_in_coronal_2d",
            "freeform_cut",
            "add_landmark_in_coronal_and_3d_viewports_and_zoom",
            "define_vessel_in_coronal",
            "navigate_to_series_segementation_and_disable_skull_removal",
            "store_five_angles_in_planning_task",
            "undo_and_redo_freeform_cut",
            "undo_and_redo_freeform_cut",
            "activate_cropping_tool_and_remove_skull",
            "recall_third_run_and_create_and_store_fluro_head_vaso_ct",
            "store_five_angles_in_planning_task",
            "recall_third_run_and_create_and_store_fluro_head_vaso_ct",
            "undo_and_redo_freeform_cut",
            "slab_interaction_in_axial_view_from_coronal",
            "define_lesion_in_coronal_2d",
            "navigate_to_series_task_and_create_new_recon_with_stent_opt",
            "quick_measurements_in_coronal_view",
            "navigate_to_series_segementation_and_disable_skull_removal",
            "add_landmark_in_coronal_and_3d_viewports_and_zoom",
            "store_five_angles_in_planning_task",
            "recall_third_run_and_create_and_store_fluro_head_vaso_ct",
            "navigate_to_series_task_and_create_new_recon_with_stent_opt",
            "navigate_to_series_task_and_create_new_recon_with_stent_opt",
            "create_and_store_fluro_run_head_coronary_in_live_task",
            "freeform_cut",
            "store_five_angles_in_planning_task",
            "define_lesion_in_coronal_2d",
            "navigate_to_series_task_and_create_new_recon_with_stent_opt",
            "slab_interaction_in_axial_view_from_coronal",
            "store_five_angles_in_planning_task",
            "activate_cropping_tool_and_remove_skull",
            "recall_third_run_and_create_and_store_fluro_head_vaso_ct",
            "freeform_cut",
            "store_five_angles_in_planning_task",
            "navigate_to_series_task_and_create_new_recon_with_stent_opt",
            "store_current_angle_roll_and_store_again_in_planning_task",
            "navigate_to_series_segementation_and_disable_skull_removal",
            "add_landmark_in_coronal_and_3d_viewports_and_zoom",
            "create_and_store_fluro_run_head_coronary_in_live_task",
            "create_and_store_fluro_run_head_coronary_in_live_task",
            "activate_cropping_tool_and_remove_skull",
            "quick_measurements_in_coronal_view"
          ],
          "2": [
            "define_vessel_in_coronal",
            "navigate_to_series_segementation_and_disable_skull_removal",
            "freeform_cut",
            "define_vessel_in_coronal",
            "store_current_angle_roll_and_store_again_in_planning_task",
            "activate_cropping_tool_and_remove_skull",
            "add_landmark_in_coronal_and_3d_viewports_and_zoom",
            "recall_third_run_and_create_and_store_fluro_head_vaso_ct",
            "create_and_store_fluro_run_head_coronary_in_live_task",
            "define_lesion_in_coronal_2d",
            "activate_cropping_tool_and_remove_skull",
            "navigate_to_series_segementation_and_disable_skull_removal",
            "freeform_cut",
            "add_landmark_in_coronal_and_3d_viewports_and_zoom",
            "store_current_angle_roll_and_store_again_in_planning_task",
            "undo_and_redo_freeform_cut",
            "undo_and_redo_freeform_cut",
            "define_lesion_in_coronal_2d",
            "slab_interaction_in_axial_view_from_coronal",
            "activate_cropping_tool_and_remove_skull",
            "quick_measurements_in_coronal_view",
            "navigate_to_series_segementation_and_disable_skull_removal",
            "add_landmark_in_coronal_and_3d_viewports_and_zoom"
          ],
          "3": [
            "recall_third_run_and_create_and_store_fluro_head_vaso_ct",
            "navigate_to_series_segementation_and_disable_skull_removal",
            "store_five_angles_in_planning_task",
            "add_landmark_in_coronal_and_3d_viewports_and_zoom",
            "activate_cropping_tool_and_remove_skull"
          ],
          "20": [
            "activate_cropping_tool_and_remove_skull",
            "navigate_to_series_segementation_and_disable_skull_removal",
            "add_landmark_in_coronal_and_3d_viewports_and_zoom"
          ],
          "4": [
            "freeform_cut",
            "undo_and_redo_freeform_cut",
            "store_current_angle_roll_and_store_again_in_planning_task",
            "define_lesion_in_coronal_2d"
          ],
          "5": [
            "freeform_cut",
            "define_lesion_in_coronal_2d",
            "undo_and_redo_freeform_cut"
          ],
          "25": [
            "navigate_to_series_task_and_create_new_recon_with_stent_opt"
          ],
          "27": [
            "define_vessel_in_coronal"
          ],
          "28": [
            "quick_measurements_in_coronal_view",
            "slab_interaction_in_axial_view_from_coronal"
          ]
        }
      },
      "statisticsString": "",
      "similarities": [{
        "existingTest": "Scenario: NeuroHQ procedure clinical workflow",
        "simScores": [
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT0 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT1 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT2 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT3 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT4 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT5 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT6 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT7 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT8 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT9 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT10 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT11 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT12 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT13 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT14 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT15 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT16 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT17 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT18 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT19 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT20 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT21 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT22 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT0 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT1 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT2 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT3 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT4 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT5 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT6 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT7 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT8 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT9 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT10 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT11 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT12 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT13 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT14 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT15 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT16 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT17 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT18 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT19 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT20 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT21 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT22 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT0 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT1 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 11.864406779661019
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT2 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 13.559322033898303
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT3 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT4 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 13.559322033898303
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT5 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 11.864406779661019
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT6 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT7 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT8 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT9 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT10 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT11 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT12 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 11.864406779661019
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT13 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 11.864406779661019
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT14 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT15 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 11.864406779661019
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT16 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 11.864406779661019
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT17 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 11.864406779661019
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT18 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 11.864406779661019
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT19 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT20 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 10.169491525423723
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT21 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 11.864406779661019
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT22 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 37.5,
            "normalizedEditDistance": 11.864406779661019
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT0 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT1 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT2 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT3 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT4 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT5 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT6 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT7 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT8 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT9 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT10 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT11 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT12 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT13 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT14 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT15 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT16 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT17 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT18 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT19 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT20 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT21 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT22 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 22.499999999999996,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT0 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT1 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT2 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT3 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT4 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT5 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT6 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT7 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT8 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT9 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT10 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT11 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT12 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT13 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT14 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT15 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT16 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT17 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 13.33333333333333
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT18 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT19 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT20 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT21 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          },
          {
            "newTestId": "ClinicalWorkflow_of_Cone_Beam_CT22 - Clinical Workflow_of Cone Beam CT",
            "jaccardIndex": 17.500000000000004,
            "normalizedEditDistance": 15.555555555555555
          }
        ]
      }]
    },
    {
      "constraintName": "ClinicalWorkflow_of_CBCT",
      "constraintText": [
        "<- whenever store current angle roll and store again in planning task occurs then reference line centering and movement in coronal axial and sagittal, quick measurements in 3d view, change slab thickness in axial must have-occurred-before",
        "reference line centering and movement in coronal axial and sagittal, quick measurements in 3d view, change slab thickness in axial, navigate to series and create new reconstruction, store current angle roll and store again in planning task occurs-at-most 1 times",
        "exposure run and launch smartCT with epx abdomen cbct closed prop, exposure run and launch smartCT with epx abdomen cbct open prop occurs-first",
        "exposure run and launch smartCT with epx abdomen cbct closed prop, exposure run and launch smartCT with epx abdomen cbct open prop occurs-at-most 1 times",
        "opacity on TSM occurs-last",
        "-> if exposure run and launch smartCT with epx abdomen cbct closed prop occurs then exposure run and launch smartCT with epx abdomen cbct open prop must not eventually-follow",
        "-> if exposure run and launch smartCT with epx abdomen cbct open prop occurs then exposure run and launch smartCT with epx abdomen cbct closed prop must not eventually-follow",
        "> if exposure run and launch smartCT with epx abdomen cbct open prop, exposure run and launch smartCT with epx abdomen cbct closed prop occurs then default main view is Axial in the layout must immediately-follow",
        "< whenever default main view is Axial in the layout occurs then exposure run and launch smartCT with epx abdomen cbct closed prop, exposure run and launch smartCT with epx abdomen cbct open prop must have-occurred-immediately-before",
        "<> if store current angle roll and store again in planning task then create and store fluro run abdomen cbct closed in live task must-immediately-follow, and vice-versa",
        "<> if create and store fluro run abdomen cbct closed in live task then recall second angle create and store fluro run abdomen cbct must-immediately-follow, and vice-versa",
        "< whenever opacity on TSM occurs then recall second angle create and store fluro run abdomen cbct, create and store fluro run abdomen cbct closed in live task must have-occurred-immediately-before",
        "> if default main view is Axial in the layout occurs then reference line centering and movement in coronal axial and sagittal, quick measurements in 3d view, change slab thickness in axial, navigate to series and create new reconstruction must immediately-follow",
        "-> if exposure run and launch smartCT with epx abdomen cbct closed prop occurs then navigate to series and create new reconstruction must not eventually-follow"
      ],
      "constraintDot": "ZGlncmFwaCBBdXRvbWF0b24gewogIHJhbmtkaXIgPSBMUjsKICAwIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDAgLT4gMTggW2xhYmVsPSJvcGFjaXR5X29uX1RTTSJdCiAgMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxIC0+IDEgW2xhYmVsPSJBTlkiXQogIDEgLT4gMTEgW2xhYmVsPSJjaGFuZ2Vfc2xhYl90aGlja25lc3NfaW5fYXhpYWwiXQogIDIgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMiAtPiAyIFtsYWJlbD0iQU5ZIl0KICAyIC0+IDM0IFtsYWJlbD0iY2hhbmdlX3NsYWJfdGhpY2tuZXNzX2luX2F4aWFsIl0KICAzIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDMgLT4gNCBbbGFiZWw9InJlY2FsbF9zZWNvbmRfYW5nbGVfY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19ydW5fYWJkb21lbl9jYmN0Il0KICA0IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDQgLT4gOSBbbGFiZWw9Im9wYWNpdHlfb25fVFNNIl0KICA1IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDUgLT4gNSBbbGFiZWw9IkFOWSJdCiAgNSAtPiAzNiBbbGFiZWw9InF1aWNrX21lYXN1cmVtZW50c19pbl8zZF92aWV3Il0KICA1IC0+IDM3IFtsYWJlbD0icmVmZXJlbmNlX2xpbmVfY2VudGVyaW5nX2FuZF9tb3ZlbWVudF9pbl9jb3JvbmFsX2F4aWFsX2FuZF9zYWdpdHRhbCJdCiAgNiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA2IC0+IDYgW2xhYmVsPSJBTlkiXQogIDYgLT4gOCBbbGFiZWw9ImNoYW5nZV9zbGFiX3RoaWNrbmVzc19pbl9heGlhbCJdCiAgNiAtPiAxIFtsYWJlbD0icmVmZXJlbmNlX2xpbmVfY2VudGVyaW5nX2FuZF9tb3ZlbWVudF9pbl9jb3JvbmFsX2F4aWFsX2FuZF9zYWdpdHRhbCJdCiAgNyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA3IC0+IDcgW2xhYmVsPSJBTlkiXQogIDcgLT4gOCBbbGFiZWw9InF1aWNrX21lYXN1cmVtZW50c19pbl8zZF92aWV3Il0KICA3IC0+IDMwIFtsYWJlbD0icmVmZXJlbmNlX2xpbmVfY2VudGVyaW5nX2FuZF9tb3ZlbWVudF9pbl9jb3JvbmFsX2F4aWFsX2FuZF9zYWdpdHRhbCJdCiAgOCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA4IC0+IDggW2xhYmVsPSJBTlkiXQogIDggLT4gMTEgW2xhYmVsPSJyZWZlcmVuY2VfbGluZV9jZW50ZXJpbmdfYW5kX21vdmVtZW50X2luX2Nvcm9uYWxfYXhpYWxfYW5kX3NhZ2l0dGFsIl0KICA5IFtzaGFwZT1kb3VibGVjaXJjbGUsbGFiZWw9IiJdOwogIDEwIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDEwIC0+IDI2IFtsYWJlbD0icXVpY2tfbWVhc3VyZW1lbnRzX2luXzNkX3ZpZXciXQogIDEwIC0+IDE2IFtsYWJlbD0ibmF2aWdhdGVfdG9fc2VyaWVzX2FuZF9jcmVhdGVfbmV3X3JlY29uc3RydWN0aW9uIl0KICAxMCAtPiAyMiBbbGFiZWw9ImNoYW5nZV9zbGFiX3RoaWNrbmVzc19pbl9heGlhbCJdCiAgMTAgLT4gMjkgW2xhYmVsPSJyZWZlcmVuY2VfbGluZV9jZW50ZXJpbmdfYW5kX21vdmVtZW50X2luX2Nvcm9uYWxfYXhpYWxfYW5kX3NhZ2l0dGFsIl0KICAxMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxMSAtPiAxMSBbbGFiZWw9IkFOWSJdCiAgMTEgLT4gMjggW2xhYmVsPSJzdG9yZV9jdXJyZW50X2FuZ2xlX3JvbGxfYW5kX3N0b3JlX2FnYWluX2luX3BsYW5uaW5nX3Rhc2siXQogIDEyIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDEyIC0+IDI1IFtsYWJlbD0ib3BhY2l0eV9vbl9UU00iXQogIDEzIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDEzIC0+IDEzIFtsYWJlbD0iQU5ZIl0KICAxMyAtPiAzNCBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc19hbmRfY3JlYXRlX25ld19yZWNvbnN0cnVjdGlvbiJdCiAgMTMgLT4gMTkgW2xhYmVsPSJzdG9yZV9jdXJyZW50X2FuZ2xlX3JvbGxfYW5kX3N0b3JlX2FnYWluX2luX3BsYW5uaW5nX3Rhc2siXQogIDE0IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE0IC0+IDEwIFtsYWJlbD0iX2RlZmF1bHRfbWFpbl92aWV3X2lzX0F4aWFsX2luX3RoZV9sYXlvdXRfIl0KICAxNSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxNSAtPiAxMyBbbGFiZWw9InF1aWNrX21lYXN1cmVtZW50c19pbl8zZF92aWV3Il0KICAxNSAtPiAxNSBbbGFiZWw9IkFOWSJdCiAgMTUgLT4gMzcgW2xhYmVsPSJuYXZpZ2F0ZV90b19zZXJpZXNfYW5kX2NyZWF0ZV9uZXdfcmVjb25zdHJ1Y3Rpb24iXQogIDE2IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE2IC0+IDE2IFtsYWJlbD0iQU5ZIl0KICAxNiAtPiAyMSBbbGFiZWw9InF1aWNrX21lYXN1cmVtZW50c19pbl8zZF92aWV3Il0KICAxNiAtPiA1IFtsYWJlbD0iY2hhbmdlX3NsYWJfdGhpY2tuZXNzX2luX2F4aWFsIl0KICAxNiAtPiAyMyBbbGFiZWw9InJlZmVyZW5jZV9saW5lX2NlbnRlcmluZ19hbmRfbW92ZW1lbnRfaW5fY29yb25hbF9heGlhbF9hbmRfc2FnaXR0YWwiXQogIDE3IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE3IC0+IDAgW2xhYmVsPSJyZWNhbGxfc2Vjb25kX2FuZ2xlX2NyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fY2JjdCJdCiAgMTggW3NoYXBlPWRvdWJsZWNpcmNsZSxsYWJlbD0iIl07CiAgMTkgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMTkgLT4gMyBbbGFiZWw9ImNyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fY2JjdF9jbG9zZWRfaW5fbGl2ZV90YXNrIl0KICAyMCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyMCAtPiAxNyBbbGFiZWw9ImNyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fY2JjdF9jbG9zZWRfaW5fbGl2ZV90YXNrIl0KICAyMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyMSAtPiAyMSBbbGFiZWw9IkFOWSJdCiAgMjEgLT4gMzYgW2xhYmVsPSJjaGFuZ2Vfc2xhYl90aGlja25lc3NfaW5fYXhpYWwiXQogIDIxIC0+IDIgW2xhYmVsPSJyZWZlcmVuY2VfbGluZV9jZW50ZXJpbmdfYW5kX21vdmVtZW50X2luX2Nvcm9uYWxfYXhpYWxfYW5kX3NhZ2l0dGFsIl0KICAyMiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyMiAtPiAyMiBbbGFiZWw9IkFOWSJdCiAgMjIgLT4gMzIgW2xhYmVsPSJxdWlja19tZWFzdXJlbWVudHNfaW5fM2RfdmlldyJdCiAgMjIgLT4gNSBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc19hbmRfY3JlYXRlX25ld19yZWNvbnN0cnVjdGlvbiJdCiAgMjIgLT4gMTUgW2xhYmVsPSJyZWZlcmVuY2VfbGluZV9jZW50ZXJpbmdfYW5kX21vdmVtZW50X2luX2Nvcm9uYWxfYXhpYWxfYW5kX3NhZ2l0dGFsIl0KICAyMyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyMyAtPiAyIFtsYWJlbD0icXVpY2tfbWVhc3VyZW1lbnRzX2luXzNkX3ZpZXciXQogIDIzIC0+IDIzIFtsYWJlbD0iQU5ZIl0KICAyMyAtPiAzNyBbbGFiZWw9ImNoYW5nZV9zbGFiX3RoaWNrbmVzc19pbl9heGlhbCJdCiAgMjQgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjQgLT4gNiBbbGFiZWw9InF1aWNrX21lYXN1cmVtZW50c19pbl8zZF92aWV3Il0KICAyNCAtPiA3IFtsYWJlbD0iY2hhbmdlX3NsYWJfdGhpY2tuZXNzX2luX2F4aWFsIl0KICAyNCAtPiAzMSBbbGFiZWw9InJlZmVyZW5jZV9saW5lX2NlbnRlcmluZ19hbmRfbW92ZW1lbnRfaW5fY29yb25hbF9heGlhbF9hbmRfc2FnaXR0YWwiXQogIDI1IFtzaGFwZT1kb3VibGVjaXJjbGUsbGFiZWw9IiJdOwogIDI2IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDI2IC0+IDI2IFtsYWJlbD0iQU5ZIl0KICAyNiAtPiAyMSBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc19hbmRfY3JlYXRlX25ld19yZWNvbnN0cnVjdGlvbiJdCiAgMjYgLT4gMzIgW2xhYmVsPSJjaGFuZ2Vfc2xhYl90aGlja25lc3NfaW5fYXhpYWwiXQogIDI2IC0+IDM1IFtsYWJlbD0icmVmZXJlbmNlX2xpbmVfY2VudGVyaW5nX2FuZF9tb3ZlbWVudF9pbl9jb3JvbmFsX2F4aWFsX2FuZF9zYWdpdHRhbCJdCiAgMjcgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgaW5pdGlhbCBbc2hhcGU9cGxhaW50ZXh0LGxhYmVsPSIiXTsKICBpbml0aWFsIC0+IDI3CiAgMjcgLT4gMzMgW2xhYmVsPSJleHBvc3VyZV9ydW5fYW5kX2xhdW5jaF9zbWFydENUX3dpdGhfZXB4X2FiZG9tZW5fY2JjdF9jbG9zZWRfcHJvcCJdCiAgMjcgLT4gMTQgW2xhYmVsPSJleHBvc3VyZV9ydW5fYW5kX2xhdW5jaF9zbWFydENUX3dpdGhfZXB4X2FiZG9tZW5fY2JjdF9vcGVuX3Byb3AiXQogIDI4IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDI4IC0+IDM4IFtsYWJlbD0iY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19ydW5fYWJkb21lbl9jYmN0X2Nsb3NlZF9pbl9saXZlX3Rhc2siXQogIDI5IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDI5IC0+IDI5IFtsYWJlbD0iQU5ZIl0KICAyOSAtPiAzNSBbbGFiZWw9InF1aWNrX21lYXN1cmVtZW50c19pbl8zZF92aWV3Il0KICAyOSAtPiAyMyBbbGFiZWw9Im5hdmlnYXRlX3RvX3Nlcmllc19hbmRfY3JlYXRlX25ld19yZWNvbnN0cnVjdGlvbiJdCiAgMjkgLT4gMTUgW2xhYmVsPSJjaGFuZ2Vfc2xhYl90aGlja25lc3NfaW5fYXhpYWwiXQogIDMwIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDMwIC0+IDExIFtsYWJlbD0icXVpY2tfbWVhc3VyZW1lbnRzX2luXzNkX3ZpZXciXQogIDMwIC0+IDMwIFtsYWJlbD0iQU5ZIl0KICAzMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzMSAtPiAxIFtsYWJlbD0icXVpY2tfbWVhc3VyZW1lbnRzX2luXzNkX3ZpZXciXQogIDMxIC0+IDMxIFtsYWJlbD0iQU5ZIl0KICAzMSAtPiAzMCBbbGFiZWw9ImNoYW5nZV9zbGFiX3RoaWNrbmVzc19pbl9heGlhbCJdCiAgMzIgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMzIgLT4gMzIgW2xhYmVsPSJBTlkiXQogIDMyIC0+IDM2IFtsYWJlbD0ibmF2aWdhdGVfdG9fc2VyaWVzX2FuZF9jcmVhdGVfbmV3X3JlY29uc3RydWN0aW9uIl0KICAzMiAtPiAxMyBbbGFiZWw9InJlZmVyZW5jZV9saW5lX2NlbnRlcmluZ19hbmRfbW92ZW1lbnRfaW5fY29yb25hbF9heGlhbF9hbmRfc2FnaXR0YWwiXQogIDMzIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDMzIC0+IDI0IFtsYWJlbD0iX2RlZmF1bHRfbWFpbl92aWV3X2lzX0F4aWFsX2luX3RoZV9sYXlvdXRfIl0KICAzNCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzNCAtPiAzNCBbbGFiZWw9IkFOWSJdCiAgMzQgLT4gMjAgW2xhYmVsPSJzdG9yZV9jdXJyZW50X2FuZ2xlX3JvbGxfYW5kX3N0b3JlX2FnYWluX2luX3BsYW5uaW5nX3Rhc2siXQogIDM1IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDM1IC0+IDM1IFtsYWJlbD0iQU5ZIl0KICAzNSAtPiAyIFtsYWJlbD0ibmF2aWdhdGVfdG9fc2VyaWVzX2FuZF9jcmVhdGVfbmV3X3JlY29uc3RydWN0aW9uIl0KICAzNSAtPiAxMyBbbGFiZWw9ImNoYW5nZV9zbGFiX3RoaWNrbmVzc19pbl9heGlhbCJdCiAgMzYgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMzYgLT4gMzYgW2xhYmVsPSJBTlkiXQogIDM2IC0+IDM0IFtsYWJlbD0icmVmZXJlbmNlX2xpbmVfY2VudGVyaW5nX2FuZF9tb3ZlbWVudF9pbl9jb3JvbmFsX2F4aWFsX2FuZF9zYWdpdHRhbCJdCiAgMzcgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMzcgLT4gMzQgW2xhYmVsPSJxdWlja19tZWFzdXJlbWVudHNfaW5fM2RfdmlldyJdCiAgMzcgLT4gMzcgW2xhYmVsPSJBTlkiXQogIDM4IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDM4IC0+IDEyIFtsYWJlbD0icmVjYWxsX3NlY29uZF9hbmdsZV9jcmVhdGVfYW5kX3N0b3JlX2ZsdXJvX3J1bl9hYmRvbWVuX2NiY3QiXQp9Cg==",
      "configurations": [],
      "featureFileLocation": "ClinicalWorkflow_of_CBCT.feature",
      "statistics": {
        "algorithm": "DFS",
        "amountOfStatesInAutomaton": 39,
        "amountOfTransitionsInAutomaton": 82,
        "amountOfTransitionsCoveredByExistingScenarios": 0,
        "amountOfPaths": 25,
        "amountOfSteps": 239,
        "percentageTransitionsCoveredByExistingScenarios": 0.0,
        "averageAmountOfStepsPerSequence": 9.56,
        "percentageOfStatesCovered": 1.0,
        "percentageOfTransitionsCovered": 0.7317073170731707,
        "averageTransitionExecution": 3.9833333333333334,
        "timesTransitionIsExecuted": {
          "1": [
            "quick_measurements_in_3d_view",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "change_slab_thickness_in_axial",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "navigate_to_series_and_create_new_reconstruction",
            "quick_measurements_in_3d_view",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "quick_measurements_in_3d_view",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "change_slab_thickness_in_axial",
            "change_slab_thickness_in_axial",
            "navigate_to_series_and_create_new_reconstruction",
            "navigate_to_series_and_create_new_reconstruction",
            "quick_measurements_in_3d_view",
            "change_slab_thickness_in_axial",
            "change_slab_thickness_in_axial",
            "navigate_to_series_and_create_new_reconstruction"
          ],
          "2": [
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "navigate_to_series_and_create_new_reconstruction",
            "quick_measurements_in_3d_view",
            "change_slab_thickness_in_axial",
            "quick_measurements_in_3d_view",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "navigate_to_series_and_create_new_reconstruction",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "quick_measurements_in_3d_view",
            "quick_measurements_in_3d_view",
            "quick_measurements_in_3d_view",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "quick_measurements_in_3d_view",
            "change_slab_thickness_in_axial",
            "change_slab_thickness_in_axial",
            "change_slab_thickness_in_axial",
            "navigate_to_series_and_create_new_reconstruction"
          ],
          "19": [
            "_default_main_view_is_Axial_in_the_layout_",
            "exposure_run_and_launch_smartCT_with_epx_abdomen_cbct_open_prop"
          ],
          "3": [
            "quick_measurements_in_3d_view",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "change_slab_thickness_in_axial"
          ],
          "4": [
            "navigate_to_series_and_create_new_reconstruction",
            "change_slab_thickness_in_axial"
          ],
          "5": [
            "recall_second_angle_create_and_store_fluro_run_abdomen_cbct",
            "opacity_on_TSM",
            "create_and_store_fluro_run_abdomen_cbct_closed_in_live_task",
            "change_slab_thickness_in_axial",
            "store_current_angle_roll_and_store_again_in_planning_task"
          ],
          "6": [
            "_default_main_view_is_Axial_in_the_layout_",
            "store_current_angle_roll_and_store_again_in_planning_task",
            "exposure_run_and_launch_smartCT_with_epx_abdomen_cbct_closed_prop",
            "opacity_on_TSM",
            "create_and_store_fluro_run_abdomen_cbct_closed_in_live_task",
            "recall_second_angle_create_and_store_fluro_run_abdomen_cbct",
            "quick_measurements_in_3d_view"
          ],
          "7": [
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal"
          ],
          "14": [
            "create_and_store_fluro_run_abdomen_cbct_closed_in_live_task",
            "recall_second_angle_create_and_store_fluro_run_abdomen_cbct",
            "store_current_angle_roll_and_store_again_in_planning_task",
            "opacity_on_TSM"
          ]
        }
      },
      "statisticsString": "",
      "similarities": [
        {
          "existingTest": "Scenario: User can search the area of interest in the slab stack",
          "simScores": [
            {
              "newTestId": "ClinicalWorkflow_of_3DRA0 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 28.57142857142857,
              "normalizedEditDistance": 25.0
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA1 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 28.57142857142857,
              "normalizedEditDistance": 25.0
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA2 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 28.57142857142857,
              "normalizedEditDistance": 20.93023255813954
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA23 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 28.57142857142857,
              "normalizedEditDistance": 19.565217391304344
            }
          ]
        },
        {
          "existingTest": "Scenario: Clinical workflow to verify volume cropping functionality",
          "simScores": [
            {
              "newTestId": "ClinicalWorkflow_of_3DRA0 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 21.62162162162162,
              "normalizedEditDistance": 22.22222222222222
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA1 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 21.62162162162162,
              "normalizedEditDistance": 22.22222222222222
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA2 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 21.62162162162162,
              "normalizedEditDistance": 18.6046511627907
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA3 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 24.444444444444446,
              "normalizedEditDistance": 22.72727272727273
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA4 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA5 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA6 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA7 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA8 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA9 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA10 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA11 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA12 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA13 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA14 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA15 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA16 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA17 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA18 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA19 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA20 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA21 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA22 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 22.22222222222222,
              "normalizedEditDistance": 19.999999999999996
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA23 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 21.62162162162162,
              "normalizedEditDistance": 17.391304347826086
            }
          ]
        },
        {
          "existingTest": "Scenario: TC_UID.SmartCT.FR.Tools.Basic.Opacity",
          "simScores": [
            {
              "newTestId": "ClinicalWorkflow_of_3DRA0 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.999999999999996,
              "normalizedEditDistance": 19.444444444444443
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA1 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.999999999999996,
              "normalizedEditDistance": 19.444444444444443
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA2 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.999999999999996,
              "normalizedEditDistance": 16.279069767441857
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA4 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA5 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA6 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA7 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA8 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA9 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA10 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA11 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA12 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA13 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA14 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA15 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA16 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA17 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA18 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA19 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA20 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA21 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA22 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 18.181818181818187,
              "normalizedEditDistance": 17.777777777777782
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA23 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.999999999999996,
              "normalizedEditDistance": 15.217391304347828
            }
          ]
        },
        {
          "existingTest": "Scenario: BasicInteraction of FD15",
          "simScores": [
            {
              "newTestId": "ClinicalWorkflow_of_3DRA0 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 25.0,
              "normalizedEditDistance": 18.644067796610166
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA1 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 25.0,
              "normalizedEditDistance": 18.644067796610166
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA2 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 25.0,
              "normalizedEditDistance": 18.644067796610166
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA3 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 51.06382978723404,
              "normalizedEditDistance": 37.28813559322034
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA4 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 30.508474576271183
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA5 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 20.33898305084746
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA6 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 20.33898305084746
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA7 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 22.033898305084744
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA8 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 28.8135593220339
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA9 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 28.8135593220339
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA10 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 30.508474576271183
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA11 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 18.644067796610166
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA12 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 18.644067796610166
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA13 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 18.644067796610166
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA14 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 28.8135593220339
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA15 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 18.644067796610166
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA16 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 18.644067796610166
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA17 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 28.8135593220339
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA18 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 28.8135593220339
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA19 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 25.423728813559322
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA20 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 25.423728813559322
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA21 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 28.8135593220339
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA22 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 40.0,
              "normalizedEditDistance": 27.118644067796616
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA23 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 25.0,
              "normalizedEditDistance": 16.94915254237288
            }
          ]
        },
        {
          "existingTest": "Scenario: Clinical workflow of Head 3DRA procedure",
          "simScores": [
            {
              "newTestId": "ClinicalWorkflow_of_3DRA0 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 30.909090909090907,
              "normalizedEditDistance": 40.476190476190474
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA1 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 30.909090909090907,
              "normalizedEditDistance": 40.476190476190474
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA2 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 30.909090909090907,
              "normalizedEditDistance": 34.883720930232556
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA3 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 66.0,
              "normalizedEditDistance": 47.72727272727273
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA4 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 68.88888888888889
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA5 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 77.77777777777779
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA6 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 80.0
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA7 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 77.77777777777779
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA8 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 64.44444444444444
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA9 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 66.66666666666667
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA10 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 64.44444444444444
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA11 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 71.11111111111111
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA12 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 68.88888888888889
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA13 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 73.33333333333334
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA14 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 66.66666666666667
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA15 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 71.11111111111111
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA16 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 75.55555555555556
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA17 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 66.66666666666667
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA18 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 66.66666666666667
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA19 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 68.88888888888889
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA20 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 68.88888888888889
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA21 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 66.66666666666667
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA22 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 86.36363636363636,
              "normalizedEditDistance": 66.66666666666667
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA23 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 30.909090909090907,
              "normalizedEditDistance": 32.608695652173914
            }
          ]
        },
        {
          "existingTest": "Scenario: Perform basic interactions PAN ZOOM ROLL in view ports",
          "simScores": [
            {
              "newTestId": "ClinicalWorkflow_of_3DRA3 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.555555555555555,
              "normalizedEditDistance": 11.363636363636365
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA4 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA5 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA6 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA7 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA8 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA9 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA10 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA11 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA12 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA13 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA14 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA15 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA16 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA17 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA18 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA19 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA20 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA21 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA22 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 11.111111111111116
            }
          ]
        },
        {
          "existingTest": "Scenario: Perform basic interactions window settings and slab position in view ports",
          "simScores": [
            {
              "newTestId": "ClinicalWorkflow_of_3DRA3 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.555555555555555,
              "normalizedEditDistance": 15.909090909090907
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA4 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA5 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA6 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA7 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA8 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA9 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA10 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA11 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA12 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA13 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA14 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA15 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA16 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA17 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA18 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA19 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA20 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA21 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA22 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 15.909090909090907,
              "normalizedEditDistance": 15.555555555555555
            }
          ]
        },
        {
          "existingTest": "Scenario: Measure MTBF With Clinical Workflow 3dra prop run",
          "simScores": [
            {
              "newTestId": "ClinicalWorkflow_of_3DRA0 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.14893617021276,
              "normalizedEditDistance": 25.0
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA1 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.14893617021276,
              "normalizedEditDistance": 25.0
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA2 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.14893617021276,
              "normalizedEditDistance": 20.93023255813954
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA3 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 52.27272727272727,
              "normalizedEditDistance": 50.0
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA4 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA5 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 33.333333333333336
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA6 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 33.333333333333336
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA7 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA8 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA9 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 33.333333333333336
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA10 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA11 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA12 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA13 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA14 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA15 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 37.77777777777778
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA16 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 37.77777777777778
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA17 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA18 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA19 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA20 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA21 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 35.55555555555555
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA22 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 34.6938775510204,
              "normalizedEditDistance": 37.77777777777778
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA23 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.14893617021276,
              "normalizedEditDistance": 19.565217391304344
            }
          ]
        },
        {
          "existingTest": "Scenario: TC_UID.SmartCT.FR.Tools.2DSlab.ReferenceLinesVisibility",
          "simScores": [
            {
              "newTestId": "ClinicalWorkflow_of_3DRA0 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 16.666666666666664,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA1 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 16.666666666666664,
              "normalizedEditDistance": 11.111111111111116
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA2 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 16.666666666666664,
              "normalizedEditDistance": 9.302325581395355
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA23 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 16.666666666666664,
              "normalizedEditDistance": 8.695652173913048
            }
          ]
        },
        {
          "existingTest": "Scenario: TC_UID.SmartCT.FR.Tools.QuickMeasurement",
          "simScores": [
            {
              "newTestId": "ClinicalWorkflow_of_3DRA0 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.999999999999996,
              "normalizedEditDistance": 7.692307692307687
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA1 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.999999999999996,
              "normalizedEditDistance": 7.692307692307687
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA2 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.999999999999996,
              "normalizedEditDistance": 6.976744186046513
            },
            {
              "newTestId": "ClinicalWorkflow_of_3DRA23 - Clinical Workflow of 3DRA Head and Abdomen",
              "jaccardIndex": 19.999999999999996,
              "normalizedEditDistance": 6.521739130434778
            }
          ]
        }
      ]
    },
    {
      "constraintName": "ClinicalWorkflow_of_Cone_Beam_CT",
      "constraintText": [
        "exposure run and launch smartCT with epx head cone beam ct HQ60fps10s man occurs-first",
        "exposure run and launch smartCT with epx head cone beam ct HQ60fps10s man, change visual preset and windowing in axial, change slab thickness in axial from coronal, roll rotate pan window settings in 3d, add landmark in coronal, subtraction tool is disabled in series task, navigate to segmentation task and zoom in 2d view, slab interaction through mouse ui, store five angles in planning task occurs-at-most 1 times",
        "recall third and fourth run and create and store fluro head conebeam ct occurs-last",
        "<> if exposure run and launch smartCT with epx head cone beam ct HQ60fps10s man then default main view is Axial in the layout must-immediately-follow, and vice-versa",
        "<> if store five angles in planning task then recall third and fourth run and create and store fluro head conebeam ct must-immediately-follow, and vice-versa",
        "> if default main view is Axial in the layout occurs then change visual preset and windowing in axial, change slab thickness in axial from coronal, roll rotate pan window settings in 3d, add landmark in coronal, subtraction tool is disabled in series task, navigate to segmentation task and zoom in 2d view, slab interaction through mouse ui, store five angles in planning task must immediately-follow",
        "<- whenever subtraction tool is disabled in series task, navigate to segmentation task and zoom in 2d view, slab interaction through mouse ui, store five angles in planning task occurs then change visual preset and windowing in axial, change slab thickness in axial from coronal, roll rotate pan window settings in 3d, add landmark in coronal must have-occurred-before",
        "<- whenever store five angles in planning task occurs then change visual preset and windowing in axial, change slab thickness in axial from coronal, roll rotate pan window settings in 3d, add landmark in coronal, subtraction tool is disabled in series task, navigate to segmentation task and zoom in 2d view, slab interaction through mouse ui must have-occurred-before"
      ],
      "constraintDot": "ZGlncmFwaCBBdXRvbWF0b24gewogIHJhbmtkaXIgPSBMUjsKICAwIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDAgLT4gNiBbbGFiZWw9InN1YnRyYWN0aW9uX3Rvb2xfaXNfZGlzYWJsZWRfaW5fc2VyaWVzX3Rhc2siXQogIDAgLT4gMjEgW2xhYmVsPSJuYXZpZ2F0ZV90b19zZWdtZW50YXRpb25fdGFza19hbmRfem9vbV9pbl8yZF92aWV3Il0KICAwIC0+IDAgW2xhYmVsPSJBTlkiXQogIDEgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMSAtPiAxMCBbbGFiZWw9InN0b3JlX2ZpdmVfYW5nbGVzX2luX3BsYW5uaW5nX3Rhc2siXQogIDEgLT4gMSBbbGFiZWw9IkFOWSJdCiAgMiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyIC0+IDIgW2xhYmVsPSJBTlkiXQogIDIgLT4gMTIgW2xhYmVsPSJhZGRfbGFuZG1hcmtfaW5fY29yb25hbCJdCiAgMyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzIC0+IDIgW2xhYmVsPSJjaGFuZ2Vfc2xhYl90aGlja25lc3NfaW5fYXhpYWxfZnJvbV9jb3JvbmFsIl0KICAzIC0+IDMgW2xhYmVsPSJBTlkiXQogIDMgLT4gNSBbbGFiZWw9ImFkZF9sYW5kbWFya19pbl9jb3JvbmFsIl0KICA0IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDQgLT4gMiBbbGFiZWw9InJvbGxfcm90YXRlX3Bhbl93aW5kb3dfc2V0dGluZ3NfaW5fM2QiXQogIDQgLT4gNCBbbGFiZWw9IkFOWSJdCiAgNCAtPiAyNSBbbGFiZWw9ImFkZF9sYW5kbWFya19pbl9jb3JvbmFsIl0KICA1IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDUgLT4gMTIgW2xhYmVsPSJjaGFuZ2Vfc2xhYl90aGlja25lc3NfaW5fYXhpYWxfZnJvbV9jb3JvbmFsIl0KICA1IC0+IDUgW2xhYmVsPSJBTlkiXQogIDYgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNiAtPiAxIFtsYWJlbD0ibmF2aWdhdGVfdG9fc2VnbWVudGF0aW9uX3Rhc2tfYW5kX3pvb21faW5fMmRfdmlldyJdCiAgNiAtPiA2IFtsYWJlbD0iQU5ZIl0KICA3IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDcgLT4gMTggW2xhYmVsPSJjaGFuZ2Vfc2xhYl90aGlja25lc3NfaW5fYXhpYWxfZnJvbV9jb3JvbmFsIl0KICA3IC0+IDE1IFtsYWJlbD0icm9sbF9yb3RhdGVfcGFuX3dpbmRvd19zZXR0aW5nc19pbl8zZCJdCiAgNyAtPiA4IFtsYWJlbD0iYWRkX2xhbmRtYXJrX2luX2Nvcm9uYWwiXQogIDcgLT4gOSBbbGFiZWw9ImNoYW5nZV92aXN1YWxfcHJlc2V0X2FuZF93aW5kb3dpbmdfaW5fYXhpYWwiXQogIDggW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgOCAtPiAxNiBbbGFiZWw9ImNoYW5nZV9zbGFiX3RoaWNrbmVzc19pbl9heGlhbF9mcm9tX2Nvcm9uYWwiXQogIDggLT4gMjIgW2xhYmVsPSJyb2xsX3JvdGF0ZV9wYW5fd2luZG93X3NldHRpbmdzX2luXzNkIl0KICA4IC0+IDggW2xhYmVsPSJBTlkiXQogIDggLT4gMjMgW2xhYmVsPSJjaGFuZ2VfdmlzdWFsX3ByZXNldF9hbmRfd2luZG93aW5nX2luX2F4aWFsIl0KICA5IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDkgLT4gNCBbbGFiZWw9ImNoYW5nZV9zbGFiX3RoaWNrbmVzc19pbl9heGlhbF9mcm9tX2Nvcm9uYWwiXQogIDkgLT4gMyBbbGFiZWw9InJvbGxfcm90YXRlX3Bhbl93aW5kb3dfc2V0dGluZ3NfaW5fM2QiXQogIDkgLT4gOSBbbGFiZWw9IkFOWSJdCiAgOSAtPiAyMyBbbGFiZWw9ImFkZF9sYW5kbWFya19pbl9jb3JvbmFsIl0KICAxMCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxMCAtPiAxMSBbbGFiZWw9InJlY2FsbF90aGlyZF9hbmRfZm91cnRoX3J1bl9hbmRfY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19oZWFkX2NvbmViZWFtX2N0Il0KICAxMSBbc2hhcGU9ZG91YmxlY2lyY2xlLGxhYmVsPSIiXTsKICAxMiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxMiAtPiAyNCBbbGFiZWw9InN1YnRyYWN0aW9uX3Rvb2xfaXNfZGlzYWJsZWRfaW5fc2VyaWVzX3Rhc2siXQogIDEyIC0+IDE0IFtsYWJlbD0ibmF2aWdhdGVfdG9fc2VnbWVudGF0aW9uX3Rhc2tfYW5kX3pvb21faW5fMmRfdmlldyJdCiAgMTIgLT4gMTIgW2xhYmVsPSJBTlkiXQogIDEyIC0+IDAgW2xhYmVsPSJzbGFiX2ludGVyYWN0aW9uX3Rocm91Z2hfbW91c2VfdWkiXQogIDEzIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDEzIC0+IDEzIFtsYWJlbD0iQU5ZIl0KICAxMyAtPiAyMCBbbGFiZWw9ImFkZF9sYW5kbWFya19pbl9jb3JvbmFsIl0KICAxMyAtPiAyIFtsYWJlbD0iY2hhbmdlX3Zpc3VhbF9wcmVzZXRfYW5kX3dpbmRvd2luZ19pbl9heGlhbCJdCiAgMTQgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMTQgLT4gMTkgW2xhYmVsPSJzdWJ0cmFjdGlvbl90b29sX2lzX2Rpc2FibGVkX2luX3Nlcmllc190YXNrIl0KICAxNCAtPiAxNCBbbGFiZWw9IkFOWSJdCiAgMTQgLT4gMjEgW2xhYmVsPSJzbGFiX2ludGVyYWN0aW9uX3Rocm91Z2hfbW91c2VfdWkiXQogIDE1IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE1IC0+IDEzIFtsYWJlbD0iY2hhbmdlX3NsYWJfdGhpY2tuZXNzX2luX2F4aWFsX2Zyb21fY29yb25hbCJdCiAgMTUgLT4gMTUgW2xhYmVsPSJBTlkiXQogIDE1IC0+IDIyIFtsYWJlbD0iYWRkX2xhbmRtYXJrX2luX2Nvcm9uYWwiXQogIDE1IC0+IDMgW2xhYmVsPSJjaGFuZ2VfdmlzdWFsX3ByZXNldF9hbmRfd2luZG93aW5nX2luX2F4aWFsIl0KICAxNiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxNiAtPiAyMCBbbGFiZWw9InJvbGxfcm90YXRlX3Bhbl93aW5kb3dfc2V0dGluZ3NfaW5fM2QiXQogIDE2IC0+IDE2IFtsYWJlbD0iQU5ZIl0KICAxNiAtPiAyNSBbbGFiZWw9ImNoYW5nZV92aXN1YWxfcHJlc2V0X2FuZF93aW5kb3dpbmdfaW5fYXhpYWwiXQogIDE3IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIGluaXRpYWwgW3NoYXBlPXBsYWludGV4dCxsYWJlbD0iIl07CiAgaW5pdGlhbCAtPiAxNwogIDE3IC0+IDI2IFtsYWJlbD0iZXhwb3N1cmVfcnVuX2FuZF9sYXVuY2hfc21hcnRDVF93aXRoX2VweF9oZWFkX2NvbmVfYmVhbV9jdF9IUTYwZnBzMTBzX21hbiJdCiAgMTggW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMTggLT4gMTMgW2xhYmVsPSJyb2xsX3JvdGF0ZV9wYW5fd2luZG93X3NldHRpbmdzX2luXzNkIl0KICAxOCAtPiAxOCBbbGFiZWw9IkFOWSJdCiAgMTggLT4gMTYgW2xhYmVsPSJhZGRfbGFuZG1hcmtfaW5fY29yb25hbCJdCiAgMTggLT4gNCBbbGFiZWw9ImNoYW5nZV92aXN1YWxfcHJlc2V0X2FuZF93aW5kb3dpbmdfaW5fYXhpYWwiXQogIDE5IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE5IC0+IDE5IFtsYWJlbD0iQU5ZIl0KICAxOSAtPiAxIFtsYWJlbD0ic2xhYl9pbnRlcmFjdGlvbl90aHJvdWdoX21vdXNlX3VpIl0KICAyMCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyMCAtPiAyMCBbbGFiZWw9IkFOWSJdCiAgMjAgLT4gMTIgW2xhYmVsPSJjaGFuZ2VfdmlzdWFsX3ByZXNldF9hbmRfd2luZG93aW5nX2luX2F4aWFsIl0KICAyMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyMSAtPiAxIFtsYWJlbD0ic3VidHJhY3Rpb25fdG9vbF9pc19kaXNhYmxlZF9pbl9zZXJpZXNfdGFzayJdCiAgMjEgLT4gMjEgW2xhYmVsPSJBTlkiXQogIDIyIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDIyIC0+IDIwIFtsYWJlbD0iY2hhbmdlX3NsYWJfdGhpY2tuZXNzX2luX2F4aWFsX2Zyb21fY29yb25hbCJdCiAgMjIgLT4gMjIgW2xhYmVsPSJBTlkiXQogIDIyIC0+IDUgW2xhYmVsPSJjaGFuZ2VfdmlzdWFsX3ByZXNldF9hbmRfd2luZG93aW5nX2luX2F4aWFsIl0KICAyMyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyMyAtPiAyNSBbbGFiZWw9ImNoYW5nZV9zbGFiX3RoaWNrbmVzc19pbl9heGlhbF9mcm9tX2Nvcm9uYWwiXQogIDIzIC0+IDUgW2xhYmVsPSJyb2xsX3JvdGF0ZV9wYW5fd2luZG93X3NldHRpbmdzX2luXzNkIl0KICAyMyAtPiAyMyBbbGFiZWw9IkFOWSJdCiAgMjQgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjQgLT4gMTkgW2xhYmVsPSJuYXZpZ2F0ZV90b19zZWdtZW50YXRpb25fdGFza19hbmRfem9vbV9pbl8yZF92aWV3Il0KICAyNCAtPiAyNCBbbGFiZWw9IkFOWSJdCiAgMjQgLT4gNiBbbGFiZWw9InNsYWJfaW50ZXJhY3Rpb25fdGhyb3VnaF9tb3VzZV91aSJdCiAgMjUgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjUgLT4gMTIgW2xhYmVsPSJyb2xsX3JvdGF0ZV9wYW5fd2luZG93X3NldHRpbmdzX2luXzNkIl0KICAyNSAtPiAyNSBbbGFiZWw9IkFOWSJdCiAgMjYgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjYgLT4gNyBbbGFiZWw9Il9kZWZhdWx0X21haW5fdmlld19pc19BeGlhbF9pbl90aGVfbGF5b3V0XyJdCn0K",
      "configurations": [],
      "featureFileLocation": "ClinicalWorkflow_of_Cone_Beam_CT.feature",
      "statistics": {
        "algorithm": "DFS",
        "amountOfStatesInAutomaton": 27,
        "amountOfTransitionsInAutomaton": 70,
        "amountOfTransitionsCoveredByExistingScenarios": 0,
        "amountOfPaths": 23,
        "amountOfSteps": 253,
        "percentageTransitionsCoveredByExistingScenarios": 0.0,
        "averageAmountOfStepsPerSequence": 11.0,
        "percentageOfStatesCovered": 1.0,
        "percentageOfTransitionsCovered": 0.6857142857142857,
        "averageTransitionExecution": 5.270833333333333,
        "timesTransitionIsExecuted": {
          "1": [
            "navigate_to_segmentation_task_and_zoom_in_2d_view",
            "add_landmark_in_coronal",
            "roll_rotate_pan_window_settings_in_3d",
            "add_landmark_in_coronal",
            "change_visual_preset_and_windowing_in_axial",
            "roll_rotate_pan_window_settings_in_3d",
            "slab_interaction_through_mouse_ui",
            "add_landmark_in_coronal",
            "subtraction_tool_is_disabled_in_series_task",
            "roll_rotate_pan_window_settings_in_3d",
            "change_slab_thickness_in_axial_from_coronal",
            "change_visual_preset_and_windowing_in_axial",
            "change_slab_thickness_in_axial_from_coronal",
            "change_slab_thickness_in_axial_from_coronal",
            "slab_interaction_through_mouse_ui",
            "change_visual_preset_and_windowing_in_axial",
            "subtraction_tool_is_disabled_in_series_task"
          ],
          "18": [
            "navigate_to_segmentation_task_and_zoom_in_2d_view"
          ],
          "2": [
            "change_visual_preset_and_windowing_in_axial",
            "change_visual_preset_and_windowing_in_axial",
            "roll_rotate_pan_window_settings_in_3d",
            "add_landmark_in_coronal",
            "change_slab_thickness_in_axial_from_coronal",
            "add_landmark_in_coronal",
            "slab_interaction_through_mouse_ui",
            "subtraction_tool_is_disabled_in_series_task",
            "change_visual_preset_and_windowing_in_axial",
            "navigate_to_segmentation_task_and_zoom_in_2d_view",
            "roll_rotate_pan_window_settings_in_3d",
            "change_slab_thickness_in_axial_from_coronal",
            "navigate_to_segmentation_task_and_zoom_in_2d_view",
            "change_slab_thickness_in_axial_from_coronal"
          ],
          "19": [
            "subtraction_tool_is_disabled_in_series_task",
            "slab_interaction_through_mouse_ui"
          ],
          "3": [
            "change_slab_thickness_in_axial_from_coronal",
            "change_visual_preset_and_windowing_in_axial"
          ],
          "4": [
            "add_landmark_in_coronal",
            "roll_rotate_pan_window_settings_in_3d"
          ],
          "5": [
            "add_landmark_in_coronal",
            "roll_rotate_pan_window_settings_in_3d"
          ],
          "23": [
            "recall_third_and_fourth_run_and_create_and_store_fluro_head_conebeam_ct",
            "store_five_angles_in_planning_task",
            "_default_main_view_is_Axial_in_the_layout_",
            "exposure_run_and_launch_smartCT_with_epx_head_cone_beam_ct_HQ60fps10s_man"
          ],
          "7": [
            "roll_rotate_pan_window_settings_in_3d",
            "add_landmark_in_coronal"
          ],
          "11": [
            "change_slab_thickness_in_axial_from_coronal",
            "change_visual_preset_and_windowing_in_axial"
          ]
        }
      },
      "statisticsString": "",
      "similarities": [{
        existingTest : "",
        simScores : []
      }]
    },
    {
      "constraintName": "ClinicalWorkflow_of_ABDOMEN_CBCT_DUAL",
      "constraintText": [
        "-> if exposure run and launch smartCT with epx abdomen cbct dual closed prop and save occurs then exposure run and launch smartCT with epx abdomen cbct dual open prop and save, exposure run and launch smartCT with epx abdomen cbct dual open prop must not eventually-follow",
        "-> if exposure run and launch smartCT with epx abdomen cbct dual open prop and save occurs then exposure run and launch smartCT with epx abdomen cbct dual closed prop and save, exposure run and launch smartCT with epx abdomen cbct dual closed prop must not eventually-follow",
        "exposure run and launch smartCT with epx abdomen cbct dual closed prop and save, exposure run and launch smartCT with epx abdomen cbct dual open prop and save occurs-first",
        "exposure run and launch smartCT with epx abdomen cbct dual closed prop and save, exposure run and launch smartCT with epx abdomen cbct dual open prop and save occurs-at-most 1 times",
        "opacity on TSM occurs-last",
        "<- whenever recall second angle create and store fluro run abdomen cbct dual open occurs then create and store fluro run abdomen cbct dual open in live task must have-occurred-before",
        "<- whenever recall second angle create and store fluro run abdomen cbct dual closed occurs then create and store fluro run abdomen cbct dual closed in live task must have-occurred-before",
        "< whenever opacity on TSM occurs then recall second angle create and store fluro run abdomen cbct dual open, recall second angle create and store fluro run abdomen cbct dual closed must have-occurred-immediately-before",
        "<- whenever create and store fluro run abdomen cbct dual open in live task occurs then quick measurements and interactions in segementation task for primary and overlay volumes, exposure run and launch smartCT with epx abdomen cbct dual open prop must have-occurred-before",
        "<- whenever create and store fluro run abdomen cbct dual closed in live task occurs then quick measurements and interactions in segementation task for primary and overlay volumes, exposure run and launch smartCT with epx abdomen cbct dual closed prop must have-occurred-before",
        "<> if exposure run and launch smartCT with epx abdomen cbct dual closed prop and save, exposure run and launch smartCT with epx abdomen cbct dual open prop and save then create new reconstruction successfully must-immediately-follow, and vice-versa",
        "<> if create new reconstruction successfully then store reconstruction volume as second volume must-immediately-follow, and vice-versa",
        "<> if store reconstruction volume as second volume then exposure run and launch smartCT with epx abdomen cbct dual closed prop, exposure run and launch smartCT with epx abdomen cbct dual open prop must-immediately-follow, and vice-versa",
        "overlay volumes are visible also in side by side occurs-exactly 1 times",
        "< whenever overlay volumes are visible also in side by side occurs then exposure run and launch smartCT with epx abdomen cbct dual closed prop, exposure run and launch smartCT with epx abdomen cbct dual open prop must have-occurred-immediately-before",
        "<> if overlay volumes are visible also in side by side then quick measurements and interactions in segementation task for primary and overlay volumes must-immediately-follow, and vice-versa",
        "<- whenever store current angle roll and store again in planning task occurs then quick measurements and interactions in segementation task for primary and overlay volumes must have-occurred-before"
      ],
      "constraintDot": "ZGlncmFwaCBBdXRvbWF0b24gewogIHJhbmtkaXIgPSBMUjsKICAwIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDAgLT4gOCBbbGFiZWw9ImNyZWF0ZV9uZXdfcmVjb25zdHJ1Y3Rpb25fc3VjY2Vzc2Z1bGx5Il0KICAxIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDEgLT4gMTEgW2xhYmVsPSJjcmVhdGVfbmV3X3JlY29uc3RydWN0aW9uX3N1Y2Nlc3NmdWxseSJdCiAgMiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyIC0+IDMgW2xhYmVsPSJjcmVhdGVfYW5kX3N0b3JlX2ZsdXJvX3J1bl9hYmRvbWVuX2NiY3RfZHVhbF9vcGVuX2luX2xpdmVfdGFzayJdCiAgMiAtPiAyIFtsYWJlbD0iXHUwMDg4LVx1MDA4OSJdCiAgMyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzIC0+IDMgW2xhYmVsPSJjcmVhdGVfYW5kX3N0b3JlX2ZsdXJvX3J1bl9hYmRvbWVuX2NiY3RfZHVhbF9vcGVuX2luX2xpdmVfdGFzayJdCiAgMyAtPiA1IFtsYWJlbD0icmVjYWxsX3NlY29uZF9hbmdsZV9jcmVhdGVfYW5kX3N0b3JlX2ZsdXJvX3J1bl9hYmRvbWVuX2NiY3RfZHVhbF9vcGVuIl0KICAzIC0+IDMgW2xhYmVsPSJcdTAwODgtXHUwMDg5Il0KICA0IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDQgLT4gMiBbbGFiZWw9InF1aWNrX21lYXN1cmVtZW50c19hbmRfaW50ZXJhY3Rpb25zX2luX3NlZ2VtZW50YXRpb25fdGFza19mb3JfcHJpbWFyeV9hbmRfb3ZlcmxheV92b2x1bWVzIl0KICA1IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDUgLT4gMyBbbGFiZWw9ImNyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fY2JjdF9kdWFsX29wZW5faW5fbGl2ZV90YXNrIl0KICA1IC0+IDUgW2xhYmVsPSJyZWNhbGxfc2Vjb25kX2FuZ2xlX2NyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fY2JjdF9kdWFsX29wZW4iXQogIDUgLT4gMyBbbGFiZWw9Ilx1MDA4OC1cdTAwODkiXQogIDUgLT4gMTAgW2xhYmVsPSJvcGFjaXR5X29uX1RTTSJdCiAgNiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA2IC0+IDEyIFtsYWJlbD0iZXhwb3N1cmVfcnVuX2FuZF9sYXVuY2hfc21hcnRDVF93aXRoX2VweF9hYmRvbWVuX2NiY3RfZHVhbF9vcGVuX3Byb3AiXQogIDcgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNyAtPiAxNyBbbGFiZWw9ImNyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fY2JjdF9kdWFsX2Nsb3NlZF9pbl9saXZlX3Rhc2siXQogIDcgLT4gNyBbbGFiZWw9Ilx1MDA4OC1cdTAwODkiXQogIDggW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgOCAtPiAxNSBbbGFiZWw9InN0b3JlX3JlY29uc3RydWN0aW9uX3ZvbHVtZV9hc19zZWNvbmRfdm9sdW1lIl0KICA5IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDkgLT4gNyBbbGFiZWw9InF1aWNrX21lYXN1cmVtZW50c19hbmRfaW50ZXJhY3Rpb25zX2luX3NlZ2VtZW50YXRpb25fdGFza19mb3JfcHJpbWFyeV9hbmRfb3ZlcmxheV92b2x1bWVzIl0KICAxMCBbc2hhcGU9ZG91YmxlY2lyY2xlLGxhYmVsPSIiXTsKICAxMCAtPiAzIFtsYWJlbD0iY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19ydW5fYWJkb21lbl9jYmN0X2R1YWxfb3Blbl9pbl9saXZlX3Rhc2siXQogIDEwIC0+IDUgW2xhYmVsPSJyZWNhbGxfc2Vjb25kX2FuZ2xlX2NyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fY2JjdF9kdWFsX29wZW4iXQogIDEwIC0+IDMgW2xhYmVsPSJcdTAwODgtXHUwMDg5Il0KICAxMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxMSAtPiA2IFtsYWJlbD0ic3RvcmVfcmVjb25zdHJ1Y3Rpb25fdm9sdW1lX2FzX3NlY29uZF92b2x1bWUiXQogIDEyIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDEyIC0+IDQgW2xhYmVsPSJvdmVybGF5X3ZvbHVtZXNfYXJlX3Zpc2libGVfYWxzb19pbl9zaWRlX2J5X3NpZGUiXQogIDEzIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIGluaXRpYWwgW3NoYXBlPXBsYWludGV4dCxsYWJlbD0iIl07CiAgaW5pdGlhbCAtPiAxMwogIDEzIC0+IDAgW2xhYmVsPSJleHBvc3VyZV9ydW5fYW5kX2xhdW5jaF9zbWFydENUX3dpdGhfZXB4X2FiZG9tZW5fY2JjdF9kdWFsX2Nsb3NlZF9wcm9wX2FuZF9zYXZlIl0KICAxMyAtPiAxIFtsYWJlbD0iZXhwb3N1cmVfcnVuX2FuZF9sYXVuY2hfc21hcnRDVF93aXRoX2VweF9hYmRvbWVuX2NiY3RfZHVhbF9vcGVuX3Byb3BfYW5kX3NhdmUiXQogIDE0IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE0IC0+IDE3IFtsYWJlbD0iY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19ydW5fYWJkb21lbl9jYmN0X2R1YWxfY2xvc2VkX2luX2xpdmVfdGFzayJdCiAgMTQgLT4gMTQgW2xhYmVsPSJyZWNhbGxfc2Vjb25kX2FuZ2xlX2NyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fY2JjdF9kdWFsX2Nsb3NlZCJdCiAgMTQgLT4gMTcgW2xhYmVsPSJcdTAwODgtXHUwMDg5Il0KICAxNCAtPiAxOCBbbGFiZWw9Im9wYWNpdHlfb25fVFNNIl0KICAxNSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxNSAtPiAxNiBbbGFiZWw9ImV4cG9zdXJlX3J1bl9hbmRfbGF1bmNoX3NtYXJ0Q1Rfd2l0aF9lcHhfYWJkb21lbl9jYmN0X2R1YWxfY2xvc2VkX3Byb3AiXQogIDE2IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE2IC0+IDkgW2xhYmVsPSJvdmVybGF5X3ZvbHVtZXNfYXJlX3Zpc2libGVfYWxzb19pbl9zaWRlX2J5X3NpZGUiXQogIDE3IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE3IC0+IDE3IFtsYWJlbD0iY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19ydW5fYWJkb21lbl9jYmN0X2R1YWxfY2xvc2VkX2luX2xpdmVfdGFzayJdCiAgMTcgLT4gMTQgW2xhYmVsPSJyZWNhbGxfc2Vjb25kX2FuZ2xlX2NyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fY2JjdF9kdWFsX2Nsb3NlZCJdCiAgMTcgLT4gMTcgW2xhYmVsPSJcdTAwODgtXHUwMDg5Il0KICAxOCBbc2hhcGU9ZG91YmxlY2lyY2xlLGxhYmVsPSIiXTsKICAxOCAtPiAxNyBbbGFiZWw9ImNyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fY2JjdF9kdWFsX2Nsb3NlZF9pbl9saXZlX3Rhc2siXQogIDE4IC0+IDE0IFtsYWJlbD0icmVjYWxsX3NlY29uZF9hbmdsZV9jcmVhdGVfYW5kX3N0b3JlX2ZsdXJvX3J1bl9hYmRvbWVuX2NiY3RfZHVhbF9jbG9zZWQiXQogIDE4IC0+IDE3IFtsYWJlbD0iXHUwMDg4LVx1MDA4OSJdCn0K",
      "configurations": [],
      "featureFileLocation": "ClinicalWorkflow_of_ABDOMEN_CBCT_DUAL.feature",
      "statistics": {
        "algorithm": "DFS",
        "amountOfStatesInAutomaton": 19,
        "amountOfTransitionsInAutomaton": 36,
        "amountOfTransitionsCoveredByExistingScenarios": 0,
        "amountOfPaths": 10,
        "amountOfSteps": 118,
        "percentageTransitionsCoveredByExistingScenarios": 0.0,
        "averageAmountOfStepsPerSequence": 11.8,
        "percentageOfStatesCovered": 1.0,
        "percentageOfTransitionsCovered": 0.7777777777777778,
        "averageTransitionExecution": 4.071428571428571,
        "timesTransitionIsExecuted": {
          "1": [
            "ANY",
            "recall_second_angle_create_and_store_fluro_run_abdomen_cbct_dual_open",
            "recall_second_angle_create_and_store_fluro_run_abdomen_cbct_dual_closed",
            "create_and_store_fluro_run_abdomen_cbct_dual_closed_in_live_task",
            "create_and_store_fluro_run_abdomen_cbct_dual_closed_in_live_task",
            "ANY",
            "create_and_store_fluro_run_abdomen_cbct_dual_open_in_live_task",
            "create_and_store_fluro_run_abdomen_cbct_dual_open_in_live_task",
            "ANY",
            "ANY"
          ],
          "5": [
            "quick_measurements_and_interactions_in_segementation_task_for_primary_and_overlay_volumes",
            "create_new_reconstruction_successfully",
            "quick_measurements_and_interactions_in_segementation_task_for_primary_and_overlay_volumes",
            "exposure_run_and_launch_smartCT_with_epx_abdomen_cbct_dual_closed_prop",
            "exposure_run_and_launch_smartCT_with_epx_abdomen_cbct_dual_open_prop",
            "overlay_volumes_are_visible_also_in_side_by_side",
            "create_new_reconstruction_successfully",
            "store_reconstruction_volume_as_second_volume",
            "store_reconstruction_volume_as_second_volume",
            "create_and_store_fluro_run_abdomen_cbct_dual_closed_in_live_task",
            "exposure_run_and_launch_smartCT_with_epx_abdomen_cbct_dual_open_prop_and_save",
            "exposure_run_and_launch_smartCT_with_epx_abdomen_cbct_dual_closed_prop_and_save",
            "overlay_volumes_are_visible_also_in_side_by_side",
            "create_and_store_fluro_run_abdomen_cbct_dual_open_in_live_task"
          ],
          "8": [
            "opacity_on_TSM",
            "opacity_on_TSM"
          ],
          "9": [
            "recall_second_angle_create_and_store_fluro_run_abdomen_cbct_dual_closed",
            "recall_second_angle_create_and_store_fluro_run_abdomen_cbct_dual_open"
          ]
        }
      },
      "statisticsString": "",
      "similarities": [{
        existingTest : "",
        simScores : []
      }]
    },
    {
      "constraintName": "ClinicalWorkflow_of_3DRA",
      "constraintText": [
        "<- whenever recall first angle create and store exp run occurs then create and store fluro run head coronary in live task must have-occurred-before",
        "<- whenever recall second angle create and store fluro run head 3dra occurs then create and store fluro run head 3dra in live task must have-occurred-before",
        "<- whenever recall second angle create and store fluro run abdomen 3dra occurs then create and store fluro run abdomen 3dra in live task must have-occurred-before",
        "< whenever update registration and check recall is first run occurs then recall first angle create and store exp run must have-occurred-immediately-before",
        "< whenever opacity on TSM occurs then recall second angle create and store fluro run abdomen 3dra, recall second angle create and store fluro run head 3dra must have-occurred-immediately-before",
        "<> if store current angle roll and store again in planning task, store current angle roll and store again in planning task alt then create and store fluro run head coronary in live task, create and store fluro run head 3dra in live task, create and store fluro run abdomen 3dra in live task must-immediately-follow, and vice-versa",
        "<- whenever create and store fluro run head coronary in live task, create and store fluro run head 3dra in live task occurs then exposure run and launch smartCT with epx head 3dra prop scan 4s must have-occurred-before",
        "<- whenever create and store fluro run abdomen 3dra in live task occurs then exposure run and launch smartCT with epx abdomen 3dra prop scan 4s must have-occurred-before",
        "exposure run and launch smartCT with epx head 3dra prop scan 4s, exposure run and launch smartCT with epx abdomen 3dra prop scan 4s occurs-first",
        "exposure run and launch smartCT with epx head 3dra prop scan 4s occurs-at-most 1 times",
        "exposure run and launch smartCT with epx abdomen 3dra prop scan 4s occurs-at-most 1 times",
        "change visual preset and windowing, define vessel in 3d, add landmark select and define vessel in coronal, define lesion in coronal 2d, roll rotate pan window settings in 3d, slab interaction in axial view, store current angle roll and store again in planning task, recall first angle create and store exp run, reference line centering and movement in coronal axial and sagittal, quick measurements in 3d view, change slab thickness in axial, store current angle roll and store again in planning task, recall first angle create and store exp run, opacity on TSM occurs-at-most 1 times",
        "opacity on TSM, update registration and check recall is first run occurs-last",
        "> if perform a exposure run, exposure run and launch smartCT with epx abdomen 3dra prop scan 4s, exposure run and launch smartCT with epx head 3dra prop scan 4s occurs then default main view is ThreeDVolume in the layout must immediately-follow",
        "< whenever default main view is ThreeDVolume in the layout occurs then exposure run and launch smartCT with epx abdomen 3dra prop scan 4s, exposure run and launch smartCT with epx head 3dra prop scan 4s must have-occurred-immediately-before",
        "-> if exposure run and launch smartCT with epx abdomen 3dra prop scan 4s occurs then exposure run and launch smartCT with epx head 3dra prop scan 4s must not eventually-follow",
        "-> if exposure run and launch smartCT with epx head 3dra prop scan 4s occurs then exposure run and launch smartCT with epx abdomen 3dra prop scan 4s must not eventually-follow",
        "> if default main view is ThreeDVolume in the layout occurs then roll rotate pan window settings in 3d, change visual preset and windowing, define lesion in coronal 2d, add landmark select and define vessel in coronal, define vessel in 3d, slab interaction in axial view, reference line centering and movement in coronal axial and sagittal, quick measurements in 3d view, change slab thickness in axial must immediately-follow",
        "<- whenever reference line centering and movement in coronal axial and sagittal, quick measurements in 3d view, change slab thickness in axial occurs then exposure run and launch smartCT with epx abdomen 3dra prop scan 4s must have-occurred-before",
        "<- whenever roll rotate pan window settings in 3d, change visual preset and windowing, define lesion in coronal 2d, add landmark select and define vessel in coronal, define vessel in 3d, slab interaction in axial view occurs then exposure run and launch smartCT with epx head 3dra prop scan 4s must have-occurred-before",
        "<- whenever define lesion in coronal 2d, add landmark select and define vessel in coronal, define vessel in 3d, slab interaction in axial view occurs then roll rotate pan window settings in 3d, change visual preset and windowing must have-occurred-before",
        "<- whenever quick measurements in 3d view, change slab thickness in axial occurs then reference line centering and movement in coronal axial and sagittal must have-occurred-before",
        "<- whenever store current angle roll and store again in planning task occurs then roll rotate pan window settings in 3d, define lesion in coronal 2d, add landmark select and define vessel in coronal, define vessel in 3d, slab interaction in axial view must have-occurred-before",
        "<- whenever store current angle roll and store again in planning task alt occurs then reference line centering and movement in coronal axial and sagittal, quick measurements in 3d view, change slab thickness in axial must have-occurred-before"
      ],
      "constraintDot": "ZGlncmFwaCBBdXRvbWF0b24gewogIHJhbmtkaXIgPSBMUjsKICAwIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDAgLT4gMjYgW2xhYmVsPSJkZWZpbmVfbGVzaW9uX2luX2Nvcm9uYWxfMmQiXQogIDAgLT4gMCBbbGFiZWw9IkFOWSJdCiAgMCAtPiAzMSBbbGFiZWw9ImRlZmluZV92ZXNzZWxfaW5fM2QiXQogIDAgLT4gMzggW2xhYmVsPSJhZGRfbGFuZG1hcmtfc2VsZWN0X2FuZF9kZWZpbmVfdmVzc2VsX2luX2Nvcm9uYWwiXQogIDEgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMSAtPiAxIFtsYWJlbD0iQU5ZIl0KICAxIC0+IDMgW2xhYmVsPSJjaGFuZ2Vfc2xhYl90aGlja25lc3NfaW5fYXhpYWwiXQogIDIgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMiAtPiAyIFtsYWJlbD0iQU5ZIl0KICAyIC0+IDMwIFtsYWJlbD0ic3RvcmVfY3VycmVudF9hbmdsZV9yb2xsX2FuZF9zdG9yZV9hZ2Fpbl9pbl9wbGFubmluZ190YXNrX2FsdCJdCiAgMiAtPiAyMCBbbGFiZWw9InJlY2FsbF9zZWNvbmRfYW5nbGVfY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19ydW5fYWJkb21lbl8zZHJhIl0KICAzIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDMgLT4gMyBbbGFiZWw9IkFOWSJdCiAgMyAtPiAyOSBbbGFiZWw9InN0b3JlX2N1cnJlbnRfYW5nbGVfcm9sbF9hbmRfc3RvcmVfYWdhaW5faW5fcGxhbm5pbmdfdGFza19hbHQiXQogIDQgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNCAtPiAxNiBbbGFiZWw9Il9kZWZhdWx0X21haW5fdmlld19pc19UaHJlZURWb2x1bWVfaW5fdGhlX2xheW91dF8iXQogIDUgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNSAtPiAyOCBbbGFiZWw9ImNoYW5nZV92aXN1YWxfcHJlc2V0X2FuZF93aW5kb3dpbmciXQogIDUgLT4gNyBbbGFiZWw9InJvbGxfcm90YXRlX3Bhbl93aW5kb3dfc2V0dGluZ3NfaW5fM2QiXQogIDYgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgNiAtPiA1IFtsYWJlbD0iX2RlZmF1bHRfbWFpbl92aWV3X2lzX1RocmVlRFZvbHVtZV9pbl90aGVfbGF5b3V0XyJdCiAgNyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA3IC0+IDM2IFtsYWJlbD0iY2hhbmdlX3Zpc3VhbF9wcmVzZXRfYW5kX3dpbmRvd2luZyJdCiAgNyAtPiA3IFtsYWJlbD0iQU5ZIl0KICA4IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDggLT4gOCBbbGFiZWw9IkFOWSJdCiAgOCAtPiAzNyBbbGFiZWw9InNsYWJfaW50ZXJhY3Rpb25faW5fYXhpYWxfdmlldyJdCiAgOCAtPiAxMCBbbGFiZWw9ImFkZF9sYW5kbWFya19zZWxlY3RfYW5kX2RlZmluZV92ZXNzZWxfaW5fY29yb25hbCJdCiAgOSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICA5IC0+IDkgW2xhYmVsPSJBTlkiXQogIDkgLT4gMTAgW2xhYmVsPSJkZWZpbmVfdmVzc2VsX2luXzNkIl0KICA5IC0+IDI0IFtsYWJlbD0ic2xhYl9pbnRlcmFjdGlvbl9pbl9heGlhbF92aWV3Il0KICAxMCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxMCAtPiAxMCBbbGFiZWw9IkFOWSJdCiAgMTAgLT4gMTggW2xhYmVsPSJzbGFiX2ludGVyYWN0aW9uX2luX2F4aWFsX3ZpZXciXQogIDExIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDExIC0+IDExIFtsYWJlbD0iQU5ZIl0KICAxMSAtPiA4IFtsYWJlbD0iZGVmaW5lX3Zlc3NlbF9pbl8zZCJdCiAgMTEgLT4gMjYgW2xhYmVsPSJzbGFiX2ludGVyYWN0aW9uX2luX2F4aWFsX3ZpZXciXQogIDExIC0+IDkgW2xhYmVsPSJhZGRfbGFuZG1hcmtfc2VsZWN0X2FuZF9kZWZpbmVfdmVzc2VsX2luX2Nvcm9uYWwiXQogIDEyIFtzaGFwZT1kb3VibGVjaXJjbGUsbGFiZWw9IiJdOwogIDEzIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDEzIC0+IDI3IFtsYWJlbD0iQU5ZIl0KICAxMyAtPiAxMyBbbGFiZWw9InJlY2FsbF9zZWNvbmRfYW5nbGVfY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19ydW5faGVhZF8zZHJhIl0KICAxMyAtPiAzNCBbbGFiZWw9Im9wYWNpdHlfb25fVFNNIl0KICAxNCBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxNCAtPiAyMyBbbGFiZWw9ImNyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2hlYWRfY29yb25hcnlfaW5fbGl2ZV90YXNrIl0KICAxNCAtPiAyNyBbbGFiZWw9ImNyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2hlYWRfM2RyYV9pbl9saXZlX3Rhc2siXQogIDE1IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE1IC0+IDE1IFtsYWJlbD0iQU5ZIl0KICAxNSAtPiAxIFtsYWJlbD0icXVpY2tfbWVhc3VyZW1lbnRzX2luXzNkX3ZpZXciXQogIDE1IC0+IDE3IFtsYWJlbD0iY2hhbmdlX3NsYWJfdGhpY2tuZXNzX2luX2F4aWFsIl0KICAxNiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAxNiAtPiAxNSBbbGFiZWw9InJlZmVyZW5jZV9saW5lX2NlbnRlcmluZ19hbmRfbW92ZW1lbnRfaW5fY29yb25hbF9heGlhbF9hbmRfc2FnaXR0YWwiXQogIDE3IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE3IC0+IDE3IFtsYWJlbD0iQU5ZIl0KICAxNyAtPiAzIFtsYWJlbD0icXVpY2tfbWVhc3VyZW1lbnRzX2luXzNkX3ZpZXciXQogIDE4IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDE4IC0+IDE0IFtsYWJlbD0ic3RvcmVfY3VycmVudF9hbmdsZV9yb2xsX2FuZF9zdG9yZV9hZ2Fpbl9pbl9wbGFubmluZ190YXNrIl0KICAxOCAtPiAxOCBbbGFiZWw9IkFOWSJdCiAgMTkgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMTkgLT4gMTAgW2xhYmVsPSJkZWZpbmVfbGVzaW9uX2luX2Nvcm9uYWxfMmQiXQogIDE5IC0+IDE5IFtsYWJlbD0iQU5ZIl0KICAxOSAtPiAzNSBbbGFiZWw9InNsYWJfaW50ZXJhY3Rpb25faW5fYXhpYWxfdmlldyJdCiAgMjAgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjAgLT4gMiBbbGFiZWw9IkFOWSJdCiAgMjAgLT4gMzAgW2xhYmVsPSJzdG9yZV9jdXJyZW50X2FuZ2xlX3JvbGxfYW5kX3N0b3JlX2FnYWluX2luX3BsYW5uaW5nX3Rhc2tfYWx0Il0KICAyMCAtPiAyMCBbbGFiZWw9InJlY2FsbF9zZWNvbmRfYW5nbGVfY3JlYXRlX2FuZF9zdG9yZV9mbHVyb19ydW5fYWJkb21lbl8zZHJhIl0KICAyMCAtPiAyMiBbbGFiZWw9Im9wYWNpdHlfb25fVFNNIl0KICAyMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyMSAtPiAxMiBbbGFiZWw9InVwZGF0ZV9yZWdpc3RyYXRpb25fYW5kX2NoZWNrX3JlY2FsbF9pc19maXJzdF9ydW4iXQogIDIyIFtzaGFwZT1kb3VibGVjaXJjbGUsbGFiZWw9IiJdOwogIDIzIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDIzIC0+IDIzIFtsYWJlbD0iQU5ZIl0KICAyMyAtPiAyMSBbbGFiZWw9InJlY2FsbF9maXJzdF9hbmdsZV9jcmVhdGVfYW5kX3N0b3JlX2V4cF9ydW4iXQogIDI0IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDI0IC0+IDI0IFtsYWJlbD0iQU5ZIl0KICAyNCAtPiAxOCBbbGFiZWw9ImRlZmluZV92ZXNzZWxfaW5fM2QiXQogIDI1IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIGluaXRpYWwgW3NoYXBlPXBsYWludGV4dCxsYWJlbD0iIl07CiAgaW5pdGlhbCAtPiAyNQogIDI1IC0+IDYgW2xhYmVsPSJleHBvc3VyZV9ydW5fYW5kX2xhdW5jaF9zbWFydENUX3dpdGhfZXB4X2hlYWRfM2RyYV9wcm9wX3NjYW5fNHMiXQogIDI1IC0+IDQgW2xhYmVsPSJleHBvc3VyZV9ydW5fYW5kX2xhdW5jaF9zbWFydENUX3dpdGhfZXB4X2FiZG9tZW5fM2RyYV9wcm9wX3NjYW5fNHMiXQogIDI2IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDI2IC0+IDI2IFtsYWJlbD0iQU5ZIl0KICAyNiAtPiAzNyBbbGFiZWw9ImRlZmluZV92ZXNzZWxfaW5fM2QiXQogIDI2IC0+IDI0IFtsYWJlbD0iYWRkX2xhbmRtYXJrX3NlbGVjdF9hbmRfZGVmaW5lX3Zlc3NlbF9pbl9jb3JvbmFsIl0KICAyNyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAyNyAtPiAyNyBbbGFiZWw9IkFOWSJdCiAgMjcgLT4gMTMgW2xhYmVsPSJyZWNhbGxfc2Vjb25kX2FuZ2xlX2NyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2hlYWRfM2RyYSJdCiAgMjggW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjggLT4gMjggW2xhYmVsPSJBTlkiXQogIDI4IC0+IDM2IFtsYWJlbD0icm9sbF9yb3RhdGVfcGFuX3dpbmRvd19zZXR0aW5nc19pbl8zZCJdCiAgMjkgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMjkgLT4gMiBbbGFiZWw9ImNyZWF0ZV9hbmRfc3RvcmVfZmx1cm9fcnVuX2FiZG9tZW5fM2RyYV9pbl9saXZlX3Rhc2siXQogIDMwIFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDMwIC0+IDIgW2xhYmVsPSJjcmVhdGVfYW5kX3N0b3JlX2ZsdXJvX3J1bl9hYmRvbWVuXzNkcmFfaW5fbGl2ZV90YXNrIl0KICAzMSBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzMSAtPiAzNyBbbGFiZWw9ImRlZmluZV9sZXNpb25faW5fY29yb25hbF8yZCJdCiAgMzEgLT4gMzEgW2xhYmVsPSJBTlkiXQogIDMxIC0+IDM1IFtsYWJlbD0iYWRkX2xhbmRtYXJrX3NlbGVjdF9hbmRfZGVmaW5lX3Zlc3NlbF9pbl9jb3JvbmFsIl0KICAzMiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzMiAtPiA4IFtsYWJlbD0iZGVmaW5lX2xlc2lvbl9pbl9jb3JvbmFsXzJkIl0KICAzMiAtPiAzMiBbbGFiZWw9IkFOWSJdCiAgMzIgLT4gMzEgW2xhYmVsPSJzbGFiX2ludGVyYWN0aW9uX2luX2F4aWFsX3ZpZXciXQogIDMyIC0+IDE5IFtsYWJlbD0iYWRkX2xhbmRtYXJrX3NlbGVjdF9hbmRfZGVmaW5lX3Zlc3NlbF9pbl9jb3JvbmFsIl0KICAzMyBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzMyAtPiA5IFtsYWJlbD0iZGVmaW5lX2xlc2lvbl9pbl9jb3JvbmFsXzJkIl0KICAzMyAtPiAzMyBbbGFiZWw9IkFOWSJdCiAgMzMgLT4gMTkgW2xhYmVsPSJkZWZpbmVfdmVzc2VsX2luXzNkIl0KICAzMyAtPiAzOCBbbGFiZWw9InNsYWJfaW50ZXJhY3Rpb25faW5fYXhpYWxfdmlldyJdCiAgMzQgW3NoYXBlPWRvdWJsZWNpcmNsZSxsYWJlbD0iIl07CiAgMzUgW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMzUgLT4gMTggW2xhYmVsPSJkZWZpbmVfbGVzaW9uX2luX2Nvcm9uYWxfMmQiXQogIDM1IC0+IDM1IFtsYWJlbD0iQU5ZIl0KICAzNiBbc2hhcGU9Y2lyY2xlLGxhYmVsPSIiXTsKICAzNiAtPiAxMSBbbGFiZWw9ImRlZmluZV9sZXNpb25faW5fY29yb25hbF8yZCJdCiAgMzYgLT4gMzYgW2xhYmVsPSJBTlkiXQogIDM2IC0+IDMyIFtsYWJlbD0iZGVmaW5lX3Zlc3NlbF9pbl8zZCJdCiAgMzYgLT4gMCBbbGFiZWw9InNsYWJfaW50ZXJhY3Rpb25faW5fYXhpYWxfdmlldyJdCiAgMzYgLT4gMzMgW2xhYmVsPSJhZGRfbGFuZG1hcmtfc2VsZWN0X2FuZF9kZWZpbmVfdmVzc2VsX2luX2Nvcm9uYWwiXQogIDM3IFtzaGFwZT1jaXJjbGUsbGFiZWw9IiJdOwogIDM3IC0+IDM3IFtsYWJlbD0iQU5ZIl0KICAzNyAtPiAxOCBbbGFiZWw9ImFkZF9sYW5kbWFya19zZWxlY3RfYW5kX2RlZmluZV92ZXNzZWxfaW5fY29yb25hbCJdCiAgMzggW3NoYXBlPWNpcmNsZSxsYWJlbD0iIl07CiAgMzggLT4gMjQgW2xhYmVsPSJkZWZpbmVfbGVzaW9uX2luX2Nvcm9uYWxfMmQiXQogIDM4IC0+IDM4IFtsYWJlbD0iQU5ZIl0KICAzOCAtPiAzNSBbbGFiZWw9ImRlZmluZV92ZXNzZWxfaW5fM2QiXQp9Cg==",
      "configurations": [],
      "featureFileLocation": "ClinicalWorkflow_of_3DRA.feature",
      "statistics": {
        "algorithm": "DFS",
        "amountOfStatesInAutomaton": 39,
        "amountOfTransitionsInAutomaton": 88,
        "amountOfTransitionsCoveredByExistingScenarios": 0,
        "amountOfPaths": 24,
        "amountOfSteps": 281,
        "percentageTransitionsCoveredByExistingScenarios": 0.0,
        "averageAmountOfStepsPerSequence": 11.708333333333334,
        "percentageOfStatesCovered": 1.0,
        "percentageOfTransitionsCovered": 0.6704545454545454,
        "averageTransitionExecution": 4.762711864406779,
        "timesTransitionIsExecuted": {
          "1": [
            "store_current_angle_roll_and_store_again_in_planning_task_alt",
            "roll_rotate_pan_window_settings_in_3d",
            "slab_interaction_in_axial_view",
            "define_lesion_in_coronal_2d",
            "add_landmark_select_and_define_vessel_in_coronal",
            "recall_first_angle_create_and_store_exp_run",
            "define_lesion_in_coronal_2d",
            "define_vessel_in_3d",
            "store_current_angle_roll_and_store_again_in_planning_task_alt",
            "define_vessel_in_3d",
            "slab_interaction_in_axial_view",
            "change_slab_thickness_in_axial",
            "define_vessel_in_3d",
            "define_lesion_in_coronal_2d",
            "quick_measurements_in_3d_view",
            "slab_interaction_in_axial_view",
            "add_landmark_select_and_define_vessel_in_coronal",
            "change_visual_preset_and_windowing",
            "update_registration_and_check_recall_is_first_run",
            "create_and_store_fluro_run_head_coronary_in_live_task",
            "add_landmark_select_and_define_vessel_in_coronal"
          ],
          "2": [
            "define_lesion_in_coronal_2d",
            "add_landmark_select_and_define_vessel_in_coronal",
            "slab_interaction_in_axial_view",
            "create_and_store_fluro_run_abdomen_3dra_in_live_task",
            "add_landmark_select_and_define_vessel_in_coronal",
            "define_vessel_in_3d",
            "define_lesion_in_coronal_2d",
            "add_landmark_select_and_define_vessel_in_coronal",
            "slab_interaction_in_axial_view",
            "define_lesion_in_coronal_2d",
            "define_vessel_in_3d"
          ],
          "19": [
            "change_visual_preset_and_windowing",
            "roll_rotate_pan_window_settings_in_3d",
            "recall_second_angle_create_and_store_fluro_run_head_3dra",
            "create_and_store_fluro_run_head_3dra_in_live_task",
            "opacity_on_TSM"
          ],
          "3": [
            "quick_measurements_in_3d_view",
            "define_lesion_in_coronal_2d",
            "change_slab_thickness_in_axial",
            "add_landmark_select_and_define_vessel_in_coronal"
          ],
          "20": [
            "store_current_angle_roll_and_store_again_in_planning_task",
            "exposure_run_and_launch_smartCT_with_epx_head_3dra_prop_scan_4s",
            "_default_main_view_is_ThreeDVolume_in_the_layout_"
          ],
          "4": [
            "opacity_on_TSM",
            "_default_main_view_is_ThreeDVolume_in_the_layout_",
            "slab_interaction_in_axial_view",
            "reference_line_centering_and_movement_in_coronal_axial_and_sagittal",
            "create_and_store_fluro_run_abdomen_3dra_in_live_task",
            "define_vessel_in_3d",
            "store_current_angle_roll_and_store_again_in_planning_task_alt",
            "exposure_run_and_launch_smartCT_with_epx_abdomen_3dra_prop_scan_4s",
            "slab_interaction_in_axial_view",
            "define_vessel_in_3d"
          ],
          "5": [
            "slab_interaction_in_axial_view",
            "recall_second_angle_create_and_store_fluro_run_abdomen_3dra",
            "define_vessel_in_3d"
          ],
          "8": [
            "define_lesion_in_coronal_2d",
            "add_landmark_select_and_define_vessel_in_coronal"
          ]
        }
      },
      "statisticsString": "",
      "similarities": [{
        existingTest : "",
        simScores : []
      }]
    }
  ]
  };

export default conformanceCheckingReport;