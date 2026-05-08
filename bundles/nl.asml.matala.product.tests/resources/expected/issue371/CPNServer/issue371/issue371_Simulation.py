import json

def simulate(n):
    stop = False
    while not stop:
        dead_marking = False
        enabled_transition_modes = {}
        # print("Current State")
        # print("{\n\t" +
        #      "\n\t".join("{!r}: {!r},".format(k, v) for k, v in n.get_marking().items()) +
        #      "\n}")
        for t in n.transition():
            tmodes = t.modes()
            # print(tmodes)
            for mode in tmodes:
                enabled_transition_modes[t] = tmodes
                print('\n')
                print('Enabled-transition: ', t)
                print('    - with inputs: ', mode.dict())
                # print('    # with-input-modes: ')
                # for key, value in mode.dict().items():
                #    json_data = json.loads(value)
                #    print('      - var: ', key, '  ->  value:\n', json.dumps(json_data, indent=2))
                # print('     > with mode: ', mode.dict())

        # print(enabled_transition_modes)

        if not enabled_transition_modes:
            dead_marking = True

        choices = {}
        idx = 0
        for key, value in enabled_transition_modes.items():
            for elm in value:
                choices[idx] = key, elm
                idx = idx + 1

        for k1, v1 in choices.items():
            print('\n')
            print('Possible-choices: ')
            print(k1, ' : ', v1)
            # print('    + choice: ', k1, ':')
            # for k2, v2 in v1[1].items():
            #    json_data = json.loads(v2)
            #    print('    + key: ', k2, ' with-mode:\n', json.dumps(json_data, indent=2))

        if not dead_marking:
            print('\n')
            value = input("Enter Choice: ")
            print('\n')
            print('****************************************************************')
            print('Selected transition: ', choices.get(int(value)))
            t, m = choices.get(int(value))
            t.fire(m)
            print('\n')
            print('[ Transition Fired! ]')
            print('\n')
            print('Current Marking: ')
            for k in n.get_marking():
                ms = n.get_marking()[k]
                for i in ms.items():
                    json_data = json.loads(i)
                    print('    + Place: ', k, ' has token: ', json.dumps(json_data))
            print('****************************************************************')
            # self.generatePlantUML(n, True)
        else:
            print('No Enabled Transitions!!')
            stop = True


def getTransitionName(t, isDetailed):
    if isDetailed:
        return t.name
    else:
        return t.name.split('_')[0]


class Simulation:
    def __init__(self):
        self.dictTrMode = None
        self.dictTrName = None

    def getEnabledTransitionList(self, n):
        trList = []
        self.dictTrName = {}
        self.dictTrMode = {}
        for t in n.transition():
            tmodes = t.modes()
            idx = 0
            for mode in tmodes:
                # for key,value in mode.dict().items():
                # kv = ': {0}  -> {1}'.format(key,value)
                trList.append(t.name + str(idx))
                self.dictTrName.update({t.name + str(idx): t.name})
                self.dictTrMode.update({t.name + str(idx): mode})
                idx = idx + 1
        return trList
