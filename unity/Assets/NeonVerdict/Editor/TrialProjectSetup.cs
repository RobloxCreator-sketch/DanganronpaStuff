using System;
using System.IO;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
namespace NeonVerdict.Editor {
public static class TrialProjectSetup {
    const string ScenePath="Assets/NeonVerdict/Scenes/Trial.unity";
    [MenuItem("Tools/Neon Verdict/Create or Reset Trial Scene")]
    public static void Setup(){
        Directory.CreateDirectory("Assets/NeonVerdict/Scenes");
        var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
        new GameObject("Neon Verdict Game").AddComponent<NeonVerdictGame>();
        EditorSceneManager.SaveScene(scene,ScenePath);
        EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(ScenePath,true)};
        PlayerSettings.companyName="Neon Verdict";PlayerSettings.productName="Neon Verdict";PlayerSettings.bundleVersion="0.4.0";
        PlayerSettings.defaultScreenWidth=1280;PlayerSettings.defaultScreenHeight=720;PlayerSettings.fullScreenMode=FullScreenMode.Windowed;PlayerSettings.runInBackground=true;
        PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Standalone,"org.neonverdict.unity");
        EditorSceneManager.OpenScene(ScenePath);
        AssetDatabase.SaveAssets();
        Validate();
        Debug.Log("UNITY TRIAL PROJECT READY: "+Path.GetFullPath(ScenePath));
    }
    [MenuItem("Tools/Neon Verdict/Validate Trial Data")]
    public static void Validate(){
        if(TrialCase.Debates.Length!=3)throw new Exception("Expected three debates");
        for(int round=0;round<3;round++){
            int count=0;foreach(var panel in TrialCase.Debates[round]){
                if(panel.duration<=0)throw new Exception("Invalid timing");
                if(panel.IsWeak){count++;if(panel.answer!=round)throw new Exception("Wrong evidence mapping");}
            }
            if(count!=1)throw new Exception("Expected one contradiction per section");
        }
        if(!TrialCase.Correct(0,0)||TrialCase.Correct(0,1)||TrialCase.Correct(-1,0))throw new Exception("Evidence matching failed");
        Debug.Log("UNITY TRIAL DATA VALIDATED");
    }
    public static void SetupAndBuildMac(){Setup();BuildMac();}
    [MenuItem("Tools/Neon Verdict/Build Mac Game")]
    public static void BuildMac(){Build(BuildTarget.StandaloneOSX,"../NeonVerdict-Unity-Mac/Neon Verdict.app");}
    [MenuItem("Tools/Neon Verdict/Build Windows Game")]
    public static void BuildWindows(){Build(BuildTarget.StandaloneWindows64,"../NeonVerdict-Unity-Windows/NeonVerdict.exe");}
    static void Build(BuildTarget target,string destination){
        if(!BuildPipeline.IsBuildTargetSupported(BuildTargetGroup.Standalone,target))throw new Exception("Install the "+target+" build module in Unity Hub first.");
        Validate();Directory.CreateDirectory(Path.GetDirectoryName(destination));
        var report=BuildPipeline.BuildPlayer(new BuildPlayerOptions{scenes=new[]{ScenePath},locationPathName=destination,target=target,options=BuildOptions.Development});
        if(report.summary.result!=UnityEditor.Build.Reporting.BuildResult.Succeeded)throw new Exception("Build failed: "+report.summary.result);
        Debug.Log("UNITY GAME BUILT: "+Path.GetFullPath(destination));
    }
}
}
