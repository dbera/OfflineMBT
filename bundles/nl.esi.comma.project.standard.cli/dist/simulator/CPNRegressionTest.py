#!/usr/bin/env python3
#
# Copyright (c) 2024, 2025 TNO-ESI
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available
# under the terms of the MIT License which is available at
# https://opensource.org/licenses/MIT
#
# SPDX-License-Identifier: MIT
#

"""
CPNRegressionTest.py - CLI wrapper for CPN REST API.

Modes:
  1) regression-test (default)
     Usage: CPNRegressionTest.py [global flags] regression-test <model.bpmn> <scenario1.json> [scenario2.json ...]
     Or simply: CPNRegressionTest.py [global flags] <model.bpmn> <scenario1.json> [scenario2.json ...]

  2) testgen
     Usage: CPNRegressionTest.py [global flags] testgen <model.bpmn> [--num-tests 1] [--depth-limit 1000] [--out path.zip]
"""

from __future__ import annotations
import argparse
import json
import os
import sys
from typing import Any, List, Tuple

from CPNClient import CPNClient, CPNClientError


def _load_json(path: str) -> Any:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _pick_first_choice_id(id_transition_dict: dict) -> int:
    if not id_transition_dict:
        raise ValueError("No transitions available")
    keys = list(id_transition_dict.keys())
    try:
        keys_int = sorted(int(k) for k in keys)
        return keys_int[0]
    except Exception:
        k = sorted(keys)[0]
        try:
            return int(k)
        except Exception:
            return k  # type: ignore


def process_scenario(client: CPNClient, uuid: str, scenario_path: str, verbose: bool = False) -> bool:
    """Process a single scenario. Returns: (fires_count, passed_bool)."""
    scenario_json = _load_json(scenario_path)
    load_resp = client.load_scenario(uuid, scenario_json)
    steps = load_resp.get("steps")
    print(f"Replay scenario '{os.path.basename(scenario_path)}' with {steps} steps.")

    passed = True

    while True:
        try:
            enabled = client.get_enabled_transitions(uuid)
        except CPNClientError as e:
            # Friendly message when server cannot be contacted
            if "Cannot contact CPN server" in str(e):
                print(f"Cannot contact the CPN server at {client.base_url}. Please ensure it is running and reachable.")
                passed = False
                break
            # Scenario failed: print server exception if available
            err_payload = e.payload if isinstance(e.payload, dict) else {"error": str(e)}
            exception_text = (
                err_payload.get("exception")
                or err_payload.get("error")
                or err_payload.get("message")
                or json.dumps(err_payload)
            )
            print(f"Scenario FAILED while querying enabled transitions: {exception_text}")
            passed = False
            break

        id_transition_dict = enabled.get("id_transition_dict", {})
        if not id_transition_dict:
            if verbose:
                print("No enabled transitions remaining. Scenario complete.")
            break

        choice_id = _pick_first_choice_id(id_transition_dict)
        client.fire_transition(uuid, int(choice_id))

        if verbose:
            tname = id_transition_dict.get(str(choice_id), id_transition_dict.get(choice_id, "?"))
            print(f"  Fired choice {tname}")

    return passed


def cmd_regression_test(args: argparse.Namespace) -> int:
    # Validate files
    if not os.path.isfile(args.bpmn):
        print(f"Error: BPMN file not found: {args.bpmn}")
        return 2
    for s in args.scenarios:
        if not os.path.isfile(s):
            print(f"Error: Scenario file not found: {s}")
            return 2

    client = CPNClient(base_url=args.base_url, timeout=args.timeout)

    # Upload BPMN
    try:
        load = client.upload_bpmn(args.bpmn)
    except CPNClientError as e:
        if "Cannot contact CPN server" in str(e):
            print(f"Cannot contact the CPN server at {args.base_url}. Please ensure it is running and reachable.")
            return 1
        print(f"Failed to upload BPMN: {e}")
        if e.payload:
            print(json.dumps(e.payload, indent=2))
        return 1

    uuid = load.get("response", {}).get("uuid")
    if not uuid:
        print("Error: Server did not return a UUID.")
        return 1

    if args.verbose:
        msg = load.get("response", {}).get("message", "Loaded")
        print(f"BPMN loaded. UUID={uuid}. {msg}")

    passed_count = 0
    failed_count = 0

    for scenario_path in args.scenarios:
        if args.verbose:
            print(f"\nProcessing scenario: {scenario_path}")
        try:
            passed = process_scenario(client, uuid, scenario_path, verbose=args.verbose)
            if passed:
                passed_count += 1
            else:
                failed_count += 1
        except CPNClientError as e:
            if "Cannot contact CPN server" in str(e):
                print(f"Cannot contact the CPN server at {args.base_url}. Please ensure it is running and reachable.")
                failed_count += 1
                break
            print(f"Scenario failed due to server error: {e}")
            if e.payload:
                print(json.dumps(e.payload, indent=2))
            failed_count += 1
        except Exception as e:
            print(f"Scenario failed: {e}")
            failed_count += 1

    # Unload unless requested to keep
    if not args.keep_loaded:
        try:
            client.unload_bpmn(uuid)
            if args.verbose:
                print(f"\nUnloaded BPMN UUID={uuid}.")
        except Exception as e:
            print(f"Warning: failed to unload BPMN: {e}")

    total_scenarios = len(args.scenarios)
    print(f"\nReport: total={total_scenarios}, passed={passed_count}, failed={failed_count}")

    return 0 if failed_count == 0 else 1


def cmd_testgen(args: argparse.Namespace) -> int:
    if not os.path.isfile(args.bpmn):
        print(f"Error: BPMN file not found: {args.bpmn}")
        return 2

    client = CPNClient(base_url=args.base_url, timeout=max(args.timeout, 120))

    try:
        zip_path = client.generate_tests(
            bpmn_path=args.bpmn,
            num_tests=args.num_tests,
            depth_limit=args.depth_limit,
            save_to=args.out if args.out else None
        )
    except CPNClientError as e:
        if "Cannot contact CPN server" in str(e):
            print(f"Cannot contact the CPN server at {args.base_url}. Please ensure it is running and reachable.")
            return 1
        print(f"Failed to generate tests: {e}")
        if e.payload:
            print(json.dumps(e.payload, indent=2))
        return 1

    if args.verbose:
        print(f"Testcases generated and saved to: {zip_path}")
    else:
        print(zip_path)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="CPN CLI: regression-test and testgen modes.")
    parser.add_argument("--base-url", default="http://127.0.0.1:5000", help="Base URL of the CPNServer")
    parser.add_argument("--timeout", type=int, default=60, help="HTTP timeout in seconds")
    parser.add_argument("--verbose", action="store_true", help="Enable detailed per-step logs")

    subparsers = parser.add_subparsers(dest="command")

    # regression-test subcommand
    p_reg = subparsers.add_parser("regression-test", help="Run scenarios against a BPMN model")
    p_reg.add_argument("bpmn", help="Path to a BPMN file")
    p_reg.add_argument("scenarios", nargs="+", help="One or more scenario JSON files")
    p_reg.add_argument("--keep-loaded", action="store_true", help="Keep the BPMN loaded")
    p_reg.set_defaults(func=cmd_regression_test)

    # testgen subcommand
    p_tg = subparsers.add_parser("testgen", help="Generate testcases ZIP from a BPMN")
    p_tg.add_argument("bpmn", help="Path to a BPMN file")
    p_tg.add_argument("--num-tests", type=int, default=1, help="Number of testcases (default: 1)")
    p_tg.add_argument("--depth-limit", type=int, default=1000, help="Depth limit (default: 1000)")
    p_tg.add_argument("--out", help="Optional custom output path for ZIP file")
    p_tg.set_defaults(func=cmd_testgen)

    return parser


def main(argv: List[str] | None = None) -> int:
    parser = build_parser()

    # Legacy shim: insert implicit 'regression-test' AFTER global flags
    raw = list(argv) if argv is not None else sys.argv[1:]
    if raw:
        first_non_flag_idx = next((i for i, t in enumerate(raw) if not t.startswith('-')), None)
        first_token = raw[first_non_flag_idx] if first_non_flag_idx is not None else None
        if first_token not in (None, 'regression-test', 'testgen'):
            prefix = raw[:first_non_flag_idx] if first_non_flag_idx is not None else []
            rest = raw[first_non_flag_idx:] if first_non_flag_idx is not None else []
            raw = prefix + ['regression-test'] + rest
    args = parser.parse_args(raw)

    if hasattr(args, 'func'):
        return args.func(args)

    parser.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
