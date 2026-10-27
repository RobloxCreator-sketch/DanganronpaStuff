using System;
namespace NeonVerdict {
// Panel-based trial structure adapted from DREditor Alpha (CC BY 4.0).
// Original case text; see THIRD_PARTY_NOTICES.md for authors and source revision.
[Serializable] public class TrialPanel {
    public int role, answer;
    public string text, prefix, weak, suffix, shot, noise;
    public float duration;
    public bool IsWeak => !string.IsNullOrEmpty(weak);
    public TrialPanel(int speaker, string line, string track, float seconds=4.5f) {
        role=speaker; text=line; shot=track; duration=seconds; answer=-1;
    }
    public TrialPanel(string before,string target,string after,int evidence,string track,string interference) {
        role=0; prefix=before; weak=target; suffix=after; answer=evidence; shot=track; duration=6; noise=interference;
    }
}
public static class TrialCase {
    public static readonly string[] Names={"REI","AKIRA","MORGAN","SORA","JUNE","KAI","NOVA"};
    public static readonly string[] Jobs={"THE ARCHIVIST","THE RUNNER","THE DESIGNER","THE MECHANIC","THE MUSICIAN","THE BOTANIST","THE ASTRONOMER"};
    public static readonly string[] Bullets={"ACCESS LOG","GOLD THREAD","POWER REPORT"};
    public static string Evidence(int index,int culprit) {
        if(index==0)return "At 20:54, "+Names[culprit]+"'s personal key opened the archive. No other key was used.";
        if(index==1)return "A gold fiber inside the display matches the unique gold cuff on "+Names[culprit]+"'s jacket.";
        return "Power stayed on all night. The clock stopped because someone removed its battery.";
    }
    public static readonly TrialPanel[][] Debates={
        new[]{new TrialPanel(1,"The archive should have been empty.","sweep_left"),
            new TrialPanel("I ","NEVER ENTERED THE ARCHIVE",".",0,"push_in","THAT PROVES NOTHING"),
            new TrialPanel(2,"Someone's personal key was recorded.","high_angle",4)},
        new[]{new TrialPanel(2,"The display lock wasn't forced.","sweep_right",4),
            new TrialPanel("I never touched ","THAT CABINET",". Not once.",1,"dolly_zoom","YOU'RE JUST GUESSING"),
            new TrialPanel(1,"A fiber was caught inside the display.","push_in",4)},
        new[]{new TrialPanel(1,"The clock stopped at nine.","high_angle",4),
            new TrialPanel(2,"Its battery was found on the floor.","sweep_left"),
            new TrialPanel("A ","POWER CUT"," stopped the clock.",2,"dolly_zoom","IT'S OBVIOUS")}
    };
    public static readonly string[] Reasoning={
        "Your key appears in the access log at 20:54. You did enter the archive. Now, what happened at the display?",
        "The gold fiber matches your cuff. You touched the cabinet from inside. But why was the clock stopped?",
        "There was no power cut. The missing battery created a false time. The key record and fiber identify who took the seal."
    };
    public static bool Correct(int answer,int loaded) => answer>=0 && answer==loaded;
}
}
