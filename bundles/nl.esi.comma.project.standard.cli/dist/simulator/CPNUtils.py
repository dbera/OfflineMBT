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

import re
from subprocess import CompletedProcess
import typing, types
import sys, string, shutil, secrets
import importlib.util
import glob
import datetime

from abc import ABC, abstractmethod
from threading import Lock

class BPMN4SException(Exception):
    def __init__(self,cliargs:dict, result: CompletedProcess[bytes], *args):
        super().__init__(*args)
        self.result = result
        self.cliargs = cliargs
        self.stdout = result.stdout.decode('utf-8').replace('\r\n','\n')
        self.stderr = result.stderr.decode('utf-8').replace('\r\n','\n')
        self.returncode = result.returncode


class AbstractCPNControl(ABC):

    @abstractmethod
    def getCurrentMarking(self):
        pass

    @abstractmethod
    def getEnabledTransitions(self):
        pass

    @staticmethod
    @abstractmethod
    def fireEnabledTransition(self, choices, cid):
        pass

    @abstractmethod
    def getEnabledTransitions(self):
        pass

    @abstractmethod
    def saveMarking(self):
        pass

    @abstractmethod
    def gotoSavedMarking(self):
        pass


# Initializing CPN Model
pn: typing.Dict[str, AbstractCPNControl] = {}


def to_valid_variable_name(s):
    # Replace invalid characters with underscores
    s = re.sub(r'\W|^(?=\d)', '_', s)
    return s


def is_loaded_module(source, package="src-gen.simulator.CPNServer") -> bool:
    """
    pre-loads file source as a module, and
    returns a CPN instance.

    :param source: submodule to be loaded
    :param package: prefix of package in which source is found (Default: CPNServer)
    :return: loaded module
    """
    if f"{package}.{source}" in sys.modules:
        return True
    return False

def gensym(length=32, prefix="gensym_", timestamp:bool=False):
    """
    generates a fairly unique symbol, used to make a module name,
    used as a helper function for load_module

    :return: generated symbol
    """
    if timestamp:
        now = datetime.datetime.now()
        symbol = now.strftime("%Y%m%d_%H%M%S%f")
        return prefix + symbol    
    alphabet = string.ascii_uppercase + string.ascii_lowercase + string.digits
    symbol = "".join([secrets.choice(alphabet) for i in range(length)])

    return prefix + symbol

def load_module(source, package="src-gen.simulator.CPNServer") -> types.ModuleType:
    """
    pre-loads file source as a module, and
    returns a CPN instance.

    :param source: submodule to be loaded
    :param package: prefix of package in which source is found (Default: CPNServer)
    :return: loaded module
    """

    spec = importlib.util.find_spec(f".{source}", package=package)
    assert spec is not None, f"Package \"{package}.{source}\" not found!"

    module = importlib.util.module_from_spec(spec)
    sys.modules[f"{package}.{source}"] = module
    spec.loader.exec_module(module)

    pn[source] = module.new_controller()
    return module


def unload_module(source, package="src-gen.simulator.CPNServer") -> types.ModuleType:
    """
    dereferences a module, and deletes CPN instance.

    :param source: submodule to be unloaded
    :param package: prefix of package in which source is found (Default: CPNServer)
    """

    spec = importlib.util.find_spec(f".{source}", package=package)
    assert spec is not None, f"Package \"{package}.{source}\" not found!"
    
    del sys.modules[f"{package}.{source}"]
    del pn[source]



def get_cpn(name) -> AbstractCPNControl:
    """
    returns an instance of CPN using module "source"

    :param name: unique identifier for the CPN
    :return: instance of CPN controller
    """

    if not name in pn.keys():
        return None
    return pn[name]

def remove(path):
    for f in glob.glob(path):
        try: 
            shutil.rmtree(f)
        except Exception as e: 
            print(e, file=sys.stderr)

def move(orig, dest_dir):
    for f in glob.glob(orig):
        try: 
            shutil.move(f,dest_dir)
        except Exception as e: 
            print(e, file=sys.stderr)

_lock_handle_bpmn = Lock()

def lock_handle_bpmn(): return _lock_handle_bpmn
