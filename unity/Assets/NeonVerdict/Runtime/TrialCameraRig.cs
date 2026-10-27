using UnityEngine;
namespace NeonVerdict {
// Adapted from SeleniumSoul's DREditor DRTrialCamera (CC BY 4.0).
// Procedural speaker-relative tracks replace the reference Animator/pivot setup.
public class TrialCameraRig {
    Camera camera;
    Vector3 target,startPosition;
    Quaternion startRotation;
    float angle,time,duration,startFov;
    string preset;
    public void Set(Camera view,Transform actor,string shot,float seconds) {
        camera=view; target=actor.position+Vector3.up*1.65f;
        angle=Mathf.Atan2(target.x,target.z); preset=shot;
        duration=Mathf.Max(.1f,seconds); time=0;
        startPosition=view.transform.position;startRotation=view.transform.rotation;startFov=view.fieldOfView;
    }
    public void Step(float dt) {
        if(!camera)return;
        time+=dt;float t=Mathf.Clamp01(time/duration),offset=.12f,distance=4.8f,height=.35f,fov=49;
        switch(preset) {
            case "sweep_left":offset=Mathf.Lerp(-.4f,.22f,t);distance=6.5f;fov=55;break;
            case "sweep_right":offset=Mathf.Lerp(.4f,-.22f,t);distance=6.5f;fov=55;break;
            case "high_angle":height=Mathf.Lerp(3,.6f,t);distance=5.5f;offset=-.18f;break;
            case "dolly_zoom":distance=Mathf.Lerp(3.8f,6.2f,t);fov=2*Mathf.Atan(Mathf.Tan(27.5f*Mathf.Deg2Rad)*3.8f/distance)*Mathf.Rad2Deg;break;
            default:distance=Mathf.Lerp(6,3.7f,t);break;
        }
        Vector3 pos=target-new Vector3(Mathf.Sin(angle+offset),0,Mathf.Cos(angle+offset))*distance+Vector3.up*height;
        float blend=Mathf.SmoothStep(0,1,Mathf.Clamp01(time/.55f));
        camera.transform.position=Vector3.Lerp(startPosition,pos,blend);
        camera.transform.rotation=Quaternion.Slerp(startRotation,Quaternion.LookRotation(target-pos),blend);
        camera.fieldOfView=Mathf.Lerp(startFov,fov,blend);
    }
}
}
