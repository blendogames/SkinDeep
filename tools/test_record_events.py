"""Compile real Record event methods against a minimal engine adapter.

Exercises rejection routing and cross-document timeout ownership. This is a
focused event test, not an engine build. Requires a C++ compiler (CXX or c++).
"""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def method(source, signature):
    start = source.index(signature)
    opening = source.index("{", start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


ADAPTER = r'''
#include <cassert>
#include <cstdlib>
#include <map>
#include <string>
#include <strings.h>
struct idStr {
    std::string value;
    idStr(const char *s): value(s) {}
    const char *c_str() const { return value.c_str(); }
    static int Icmp(const char *a, const char *b) { return strcasecmp(a,b); }
};
struct Dict {
    std::map<std::string,std::string> values;
    const char *GetString(const char *key, const char *fallback="") const {
        auto it=values.find(key); return it==values.end()?fallback:it->second.c_str();
    }
    bool GetBool(const char *key, const char *fallback="0") const {
        return atoi(GetString(key,fallback))!=0;
    }
};
struct Hud {
    Dict state;
    const char *GetStateString(const char *k,const char *d) { return state.GetString(k,d); }
    void SetStateBool(const char *k,bool v) { state.values[k]=v?"1":"0"; }
    void StateChanged(int) {}
};
struct idEntity {
    Dict spawnArgs;
    std::string name;
    int activations=0, targets=0, removes=0;
    idEntity *lastActivator=nullptr;
    const char *GetName() const { return name.c_str(); }
    void ProcessEvent(const int *,idEntity *a) { activations++; lastActivator=a; }
    void ActivateTargets(idEntity *) { targets++; }
    void PostEventMS(const int *,int) { removes++; }
};
struct idPlayer: idEntity { Hud *hud=nullptr; };
struct Game {
    int time=0, warnings=0;
    idPlayer *player=nullptr;
    std::map<std::string,idEntity*> entities;
    idEntity *FindEntity(const char *name) { auto i=entities.find(name); return i==entities.end()?nullptr:i->second; }
    idPlayer *GetLocalPlayer() { return player; }
    void Warning(const char *,...) { warnings++; }
    void Printf(const char *,...) {}
} gameLocal;
const int EV_Activate=1, EV_Remove=2;
struct idStBrielleRecord {
    static Dict state;
    static bool Has(const char *k) { return state.values.count(k)>0; }
    static bool GetBool(const char *k,bool d) { return state.GetBool(k,d?"1":"0"); }
    static idStr GetString(const char *k,const char *d) { return state.GetString(k,d); }
};
Dict idStBrielleRecord::state;
struct idTarget_StBrielleRecordCheck: idEntity {
    bool EvaluateCondition() const;
    void Event_Activate(idEntity *);
};
struct idTarget_StBrielleNotice: idEntity { void Event_Clear(); };
'''

SCENARIOS = r'''
int main() {
    idEntity player, failure;
    idTarget_StBrielleRecordCheck check;
    check.name="gate";
    gameLocal.entities["gate"]=&check;
    gameLocal.entities["rejected"]=&failure;
    check.spawnArgs.values={{"record_key","sb_evidence"},{"record_compare","true"},
        {"record_fail_target","rejected"},{"record_once","1"}};
    check.Event_Activate(&player);
    assert(failure.activations==1 && failure.lastActivator==&player);
    assert(check.targets==0 && check.removes==0);
    idStBrielleRecord::state.values["sb_evidence"]="1";
    check.Event_Activate(&player);
    assert(check.targets==1 && check.removes==1 && failure.activations==1);
    idStBrielleRecord::state.values.clear();
    check.spawnArgs.values["record_fail_target"]="gate";
    check.Event_Activate(&player);
    assert(gameLocal.warnings==1 && check.activations==0);
    check.spawnArgs.values["record_fail_target"]="missing";
    check.Event_Activate(&player);
    assert(gameLocal.warnings==2);
    check.spawnArgs.values.erase("record_fail_target");
    check.Event_Activate(&player);
    assert(check.targets==1 && failure.activations==1); // legacy silent failure

    check.spawnArgs.values["record_compare"]="lte";
    check.spawnArgs.values["record_value"]="0";
    assert(check.EvaluateCondition()); // absent certification defaults to zero
    idStBrielleRecord::state.values["sb_evidence"]="2";
    assert(!check.EvaluateCondition());

    Hud hud;
    idPlayer local;
    local.hud=&hud;
    gameLocal.player=&local;
    idTarget_StBrielleNotice oldDocument, newDocument;
    oldDocument.name="roster"; newDocument.name="testimony";
    hud.state.values={{"sb_notice_owner","testimony"},{"sb_notice_visible","1"}};
    oldDocument.Event_Clear();
    assert(hud.state.GetBool("sb_notice_visible"));
    newDocument.Event_Clear();
    assert(!hud.state.GetBool("sb_notice_visible"));
    hud.state.values={{"sb_notice_owner","roster"},{"sb_notice_visible","1"}};
    newDocument.Event_Clear(); // reverse read order
    assert(hud.state.GetBool("sb_notice_visible"));
    oldDocument.Event_Clear();
    assert(!hud.state.GetBool("sb_notice_visible"));
    local.hud=nullptr;
    newDocument.Event_Clear();
    gameLocal.player=nullptr;
    oldDocument.Event_Clear();
}
'''


class RecordEventTests(unittest.TestCase):
    def test_actual_record_and_notice_events(self):
        source = (ROOT / "d3xp/sb_record.cpp").read_text(encoding="utf-8")
        signatures = [
            "bool idTarget_StBrielleRecordCheck::EvaluateCondition",
            "void idTarget_StBrielleRecordCheck::Event_Activate",
            "void idTarget_StBrielleNotice::Event_Clear",
        ]
        code = ADAPTER + "\n".join(method(source, signature) for signature in signatures) + SCENARIOS
        with tempfile.TemporaryDirectory() as directory:
            cpp = Path(directory) / "record_events.cpp"
            binary = Path(directory) / "record_events"
            cpp.write_text(code, encoding="utf-8")
            subprocess.run([os.environ.get("CXX", "c++"), "-std=c++11", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)


if __name__ == "__main__":
    unittest.main(verbosity=2)
