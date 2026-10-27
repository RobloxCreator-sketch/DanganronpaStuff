using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
namespace NeonVerdict {
// Original Unity implementation with selected DREditor Alpha trial-system adaptations.
// See THIRD_PARTY_NOTICES.md. No Danganronpa assets or franchise code are included.
public sealed class NeonVerdictGame : MonoBehaviour {
    public enum Phase { Menu,Dialogue,Intro,Debate,Break,Reasoning,Verdict,Result }
    public Phase State {get;private set;}
    public int Round {get;private set;}
    public int Confidence {get;private set;}=5;
    public int Selected {get;private set;}
    public int Score {get;private set;}
    public int Culprit {get;private set;}
    public Camera MainCamera;
    public Transform[] Actors=new Transform[7];
    static readonly Color Pink=new Color32(255,69,143,255),Gold=new Color32(255,209,123,255),Ink=new Color32(17,19,33,255),Pale=new Color32(238,232,229,255);
    Canvas canvas;RectTransform root,screen,effects;
    Font font;Text feedback,hud,loaded,evidence,timer,focus,reticle,noise;
    RectTransform phrase,weak,noiseRect;TrialPanel panel;
    RectTransform cylinder;Image[] chambers=new Image[6];Text[] chamberNumbers=new Text[3];
    RectTransform record;TrialCameraRig cameraRig=new TrialCameraRig();
    RenderTexture portraitTexture;Camera portraitCamera;GameObject portraitClone;
    AudioSource music,sfx;AudioClip shotClip;
    int dialogueIndex,panelIndex,sequence,shots,hits;
    float remaining=120,focusAmount=6,panelTime,noiseTime,feedbackTime,loadTime,fireCooldown,silenceCooldown,orbit,spin,desiredSpin,recoil;
    bool noiseCleared,muted;Coroutine shotRoutine;
    List<GameObject> owned=new List<GameObject>();
    void Start(){
        Culprit=UnityEngine.Random.Range(0,7);
        if(!MainCamera)BuildWorld();
        BuildUI();BuildAudio();ShowMenu();
        if(Array.IndexOf(Environment.GetCommandLineArgs(),"--trial-smoke")>=0)StartCoroutine(SmokeTest());
    }
    Material Mat(Color c,bool glow=false){
        Shader shader=Shader.Find(glow?"Unlit/Color":"Standard");if(!shader)shader=Shader.Find("Sprites/Default");
        var m=new Material(shader);m.color=c;return m;
    }
    GameObject Cube(Transform parent,Vector3 position,Vector3 size,Color color,bool glow=false){
        var g=GameObject.CreatePrimitive(PrimitiveType.Cube);g.transform.SetParent(parent,false);g.transform.localPosition=position;g.transform.localScale=size;
        g.GetComponent<Renderer>().sharedMaterial=Mat(color,glow);var collider=g.GetComponent<Collider>();if(collider)Destroy(collider);return g;
    }
    public void BuildWorld(){
        var world=new GameObject("Courtroom");world.transform.SetParent(transform,false);
        Cube(world.transform,new Vector3(0,-.2f,0),new Vector3(32,.4f,32),Ink);
        for(int i=0;i<16;i++){
            float a=i*Mathf.PI/8;var wall=new GameObject("Wall "+i);wall.transform.SetParent(world.transform,false);wall.transform.position=new Vector3(Mathf.Sin(a)*14,4,Mathf.Cos(a)*14);wall.transform.rotation=Quaternion.Euler(0,a*Mathf.Rad2Deg,0);
            Cube(wall.transform,Vector3.zero,new Vector3(5.6f,8,.5f),new Color32(29,29,48,255));
            Cube(wall.transform,new Vector3(2.3f,0,-.3f),new Vector3(.07f,6.5f,.1f),Pink,true);
            Cube(wall.transform,new Vector3(0,-3,-.3f),new Vector3(4.6f,.07f,.1f),Gold,true);
        }
        var center=GameObject.CreatePrimitive(PrimitiveType.Cylinder);center.name="Trial seal";center.transform.SetParent(world.transform,false);center.transform.localScale=new Vector3(9,.03f,9);center.GetComponent<Renderer>().sharedMaterial=Mat(new Color32(72,38,77,255));Destroy(center.GetComponent<Collider>());
        for(int i=0;i<8;i++){
            float a=i*Mathf.PI/4;var seat=new GameObject("Podium "+(i+1));seat.transform.SetParent(world.transform,false);seat.transform.position=new Vector3(Mathf.Sin(a)*9,0,Mathf.Cos(a)*9);seat.transform.rotation=Quaternion.LookRotation(-seat.transform.position);
            Cube(seat.transform,new Vector3(0,.08f,0),new Vector3(2.6f,.16f,2.2f),Pink,true);
            Cube(seat.transform,new Vector3(0,.65f,.65f),new Vector3(1.75f,1.25f,.65f),Ink);
            Cube(seat.transform,new Vector3(0,1.32f,.65f),new Vector3(2.1f,.15f,.95f),new Color32(133,101,133,255));
            if(i>0)Actors[i-1]=MakeActor(i-1,seat.transform);
        }
        RenderSettings.ambientLight=new Color(.6f,.56f,.72f);RenderSettings.fog=true;RenderSettings.fogColor=new Color(.04f,.04f,.07f);RenderSettings.fogDensity=.012f;
        var light=new GameObject("Courtroom key light");light.transform.SetParent(world.transform);light.transform.rotation=Quaternion.Euler(48,-35,0);light.AddComponent<Light>().type=LightType.Directional;light.GetComponent<Light>().intensity=1.5f;
        var cam=new GameObject("Trial Camera");cam.transform.SetParent(transform);MainCamera=cam.AddComponent<Camera>();MainCamera.backgroundColor=new Color(.025f,.025f,.05f);MainCamera.clearFlags=CameraClearFlags.SolidColor;MainCamera.farClipPlane=100;MainCamera.cullingMask=~(1<<8);cam.AddComponent<AudioListener>();
    }
    Transform MakeActor(int i,Transform parent){
        var actor=new GameObject(TrialCase.Names[i]).transform;actor.SetParent(parent,false);actor.localPosition=new Vector3(0,0,-.35f);
        Color jacket=Color.HSVToRGB(UnityEngine.Random.value,.45f,.65f);Color skin=new[]{new Color32(233,189,156,255),new Color32(184,125,85,255),new Color32(121,81,63,255)}[i%3];Color hair=Color.HSVToRGB(UnityEngine.Random.value,.3f,.28f);
        Cube(actor,new Vector3(0,1.2f,0),new Vector3(.65f,.8f,.35f),jacket);
        Cube(actor,new Vector3(0,1.35f,.19f),new Vector3(.2f,.55f,.03f),Pale);
        Cube(actor,new Vector3(0,1.42f,.22f),new Vector3(.065f,.42f,.025f),Pink);
        foreach(int side in new[]{-1,1}){
            Cube(actor,new Vector3(side*.2f,.43f,0),new Vector3(.27f,.8f,.3f),Ink);
            Cube(actor,new Vector3(side*.2f,.08f,.08f),new Vector3(.3f,.17f,.48f),Ink);
            Cube(actor,new Vector3(side*.46f,1.2f,0),new Vector3(.22f,.73f,.3f),jacket);
            Cube(actor,new Vector3(side*.46f,.83f,0),new Vector3(.21f,.2f,.26f),skin);
        }
        Cube(actor,new Vector3(0,1.96f,0),new Vector3(.5f,.55f,.45f),skin);
        Cube(actor,new Vector3(0,2.24f,0),new Vector3(.56f,.2f,.5f),hair);
        Cube(actor,new Vector3(-.22f,2.08f,0),new Vector3(.14f,.37f,.49f),hair);
        foreach(int side in new[]{-1,1})Cube(actor,new Vector3(side*.12f,1.99f,.23f),new Vector3(.065f,.045f,.025f),Ink);
        Cube(actor,new Vector3(0,1.83f,.235f),new Vector3(.1f,.02f,.015f),Pink);
        if(i==Culprit)Cube(actor,new Vector3(.46f,.99f,0),new Vector3(.24f,.1f,.33f),Gold,true);
        if(i%3==1){Cube(actor,new Vector3(0,2.4f,0),new Vector3(.7f,.12f,.6f),jacket);Cube(actor,new Vector3(0,2.5f,0),new Vector3(.48f,.2f,.44f),jacket);}
        if(i%3==0)foreach(int side in new[]{-1,1})Cube(actor,new Vector3(side*.12f,2,.25f),new Vector3(.19f,.12f,.025f),new Color32(80,106,131,255));
        return actor;
    }
    RectTransform Rect(Transform parent,string name,float x,float y,float w,float h){
        var g=new GameObject(name,typeof(RectTransform));var r=g.GetComponent<RectTransform>();r.SetParent(parent,false);r.anchorMin=r.anchorMax=new Vector2(0,1);r.pivot=new Vector2(0,1);r.anchoredPosition=new Vector2(x,-y);r.sizeDelta=new Vector2(w,h);return r;
    }
    Image Fill(Transform parent,float x,float y,float w,float h,Color color){var r=Rect(parent,"Panel",x,y,w,h);var img=r.gameObject.AddComponent<Image>();img.color=color;img.raycastTarget=false;return img;}
    Text Label(Transform parent,string value,float x,float y,float w,float h,int size=24,Color? color=null){
        var r=Rect(parent,"Text",x,y,w,h);var t=r.gameObject.AddComponent<Text>();t.font=font;t.fontSize=size;t.text=value;t.color=color??Pale;t.raycastTarget=false;t.horizontalOverflow=HorizontalWrapMode.Wrap;t.verticalOverflow=VerticalWrapMode.Overflow;
        var shadow=t.gameObject.AddComponent<Shadow>();shadow.effectColor=new Color(0,0,0,.8f);shadow.effectDistance=new Vector2(1,-1);return t;
    }
    Button Button(Transform parent,string value,float x,float y,float w,float h,Action action){
        var img=Fill(parent,x,y,w,h,new Color32(37,37,57,255));img.raycastTarget=true;var b=img.gameObject.AddComponent<Button>();b.targetGraphic=img;var colors=b.colors;colors.highlightedColor=new Color(1,.65f,.8f);b.colors=colors;b.onClick.AddListener(()=>action());
        var t=Label(img.transform,value,8,5,w-16,h-10,20);t.alignment=TextAnchor.MiddleCenter;return b;
    }
    void BuildUI(){
        font=Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        var c=new GameObject("Trial UI",typeof(RectTransform),typeof(Canvas),typeof(CanvasScaler),typeof(GraphicRaycaster));c.transform.SetParent(transform);canvas=c.GetComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceOverlay;
        var scaler=c.GetComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=new Vector2(1280,720);scaler.matchWidthOrHeight=.5f;root=c.GetComponent<RectTransform>();
        screen=Rect(root,"Screen",0,0,1280,720);effects=Rect(root,"Shot effects",0,0,1280,720);
        if(!FindAnyObjectByType<EventSystem>()){var events=new GameObject("EventSystem");events.AddComponent<EventSystem>();events.AddComponent<StandaloneInputModule>();}
        portraitTexture=new RenderTexture(440,560,16);portraitTexture.Create();
        var cameraObject=new GameObject("Portrait Camera");cameraObject.transform.SetParent(transform);portraitCamera=cameraObject.AddComponent<Camera>();portraitCamera.targetTexture=portraitTexture;portraitCamera.clearFlags=CameraClearFlags.SolidColor;portraitCamera.backgroundColor=Color.clear;portraitCamera.cullingMask=1<<8;portraitCamera.fieldOfView=34;portraitCamera.farClipPlane=20;portraitCamera.enabled=false;
    }
    void BuildAudio(){
        music=gameObject.AddComponent<AudioSource>();sfx=gameObject.AddComponent<AudioSource>();music.volume=.12f;sfx.volume=.3f;
        var samples=new float[22050*8];for(int i=0;i<samples.Length;i++){float t=i/22050f;float f=t<4?55:65.406f;samples[i]=Mathf.Sin(2*Mathf.PI*f*t)*Mathf.Exp(-(t%.5f)*8)*.4f+Mathf.Sin(2*Mathf.PI*f*4*t)*.035f;}
        var ambience=AudioClip.Create("Original trial ambience",samples.Length,1,22050,false);ambience.SetData(samples,0);music.clip=ambience;music.loop=true;music.Play();
        var shotSamples=new float[4400];for(int i=0;i<shotSamples.Length;i++){float t=i/22050f;shotSamples[i]=Mathf.Sin(2*Mathf.PI*(850*t-1800*t*t))*Mathf.Exp(-t*30)*.65f;}
        shotClip=AudioClip.Create("Evidence shot",shotSamples.Length,1,22050,false);shotClip.SetData(shotSamples,0);
    }
    void Clear(){
        sequence++;foreach(Transform child in screen)Destroy(child.gameObject);foreach(Transform child in effects)Destroy(child.gameObject);
        record=null;phrase=null;weak=null;noise=null;cylinder=null;reticle=null;noiseRect=null;loadTime=0;
        if(portraitClone)Destroy(portraitClone);if(portraitCamera)portraitCamera.enabled=false;
    }
    void ShowMenu(){
        State=Phase.Menu;Clear();Fill(screen,0,0,680,720,new Color(.035f,.04f,.07f,.95f));Fill(screen,52,82,44,4,Pink);
        Label(screen,"AN ORIGINAL UNITY TRIAL GAME",52,104,550,35,18,Gold);Label(screen,"NEON\nVERDICT",48,158,600,230,82);
        Label(screen,"CASE 01 / THE MISSING SEAL",54,400,550,38,23,Pink);
        Label(screen,"Seven witnesses. Three contradictions. One stolen seal.\nRead the evidence, break the lies, and name the culprit.",54,450,525,100,21);
        Button(screen,"BEGIN TRIAL",54,565,340,60,StartCase);Button(screen,"QUIT",413,565,155,60,()=>Application.Quit());
        Label(screen,"Unity edition / v0.4   •   Original placeholder characters",54,670,850,30,15);
    }
    public void StartCase(){Confidence=5;Score=0;Round=0;shots=hits=0;Selected=0;dialogueIndex=0;remaining=120;focusAmount=6;ShowDialogue(false);}
    void ShowPortrait(int index){
        portraitClone=Instantiate(Actors[index].gameObject);portraitClone.name="Speaker portrait";portraitClone.transform.SetParent(transform);portraitClone.transform.position=new Vector3(1000,0,0);portraitClone.transform.rotation=Quaternion.identity;
        foreach(Transform t in portraitClone.GetComponentsInChildren<Transform>())t.gameObject.layer=8;
        portraitCamera.transform.position=new Vector3(1000,1.8f,3.7f);portraitCamera.transform.LookAt(new Vector3(1000,1.65f,0));portraitCamera.enabled=true;
        var r=Rect(screen,"Portrait",24,435,235,285);var image=r.gameObject.AddComponent<RawImage>();image.texture=portraitTexture;image.raycastTarget=false;
    }
    void ShowDialogue(bool reasoning){
        State=reasoning?Phase.Reasoning:Phase.Dialogue;Clear();int other=(Culprit+2)%7;int actor=reasoning?Culprit:(dialogueIndex==1?Culprit:other);
        cameraRig.Set(MainCamera,Actors[actor],"push_in",4);
        Fill(screen,24,522,1232,174,new Color(.045f,.05f,.09f,.97f));Fill(screen,24,522,1232,3,Pink);ShowPortrait(actor);
        string[] lines={"The archive seal vanished during the reception. We have a key record, a fiber from the display, and a power report.","I didn't go anywhere near the archive. You can't prove otherwise.","Compare the testimony with the evidence. Clear purple noise with right-click, then fire the right truth bullet at the gold weak point."};
        Label(screen,reasoning?"CONTRADICTION RESOLVED / "+Round+" OF 3":TrialCase.Names[actor]+" / "+TrialCase.Jobs[actor],285,540,900,36,23,Pink);
        Label(screen,reasoning?TrialCase.Reasoning[Round-1]:lines[dialogueIndex],285,585,855,85,22);
        Button(screen,"NEXT →",1120,642,112,38,NextDialogue);
    }
    public void NextDialogue(){
        if(State==Phase.Reasoning){if(Round>=3)ShowVerdict();else StartCoroutine(Intro());return;}
        if(State!=Phase.Dialogue)return;dialogueIndex++;if(dialogueIndex>=3)StartCoroutine(Intro());else ShowDialogue(false);
    }
    IEnumerator Intro(){
        State=Phase.Intro;Clear();remaining=120;focusAmount=6;Fill(screen,0,0,1280,720,new Color(.03f,.03f,.06f,.85f));
        Label(screen,"TRUTH AGAINST TESTIMONY",298,236,850,50,24,Gold);var title=Label(screen,"NONSTOP DEBATE",-1100,300,1200,120,72,Pink);
        Label(screen,"Q / E or wheel: load evidence   •   Click: shoot   •   Right-click: clear noise\nHold Shift to focus. Tab opens the evidence record. Statements loop automatically.",200,460,1000,100,21);
        int token=sequence;float time=0;while(time<3){time+=Time.deltaTime;title.rectTransform.anchoredPosition=new Vector2(Mathf.Lerp(-1100,210,1-Mathf.Pow(1-Mathf.Clamp01(time/.45f),4)),-300);yield return null;if(token!=sequence)yield break;}ShowDebate();
    }
    void BuildCylinder(){
        cylinder=Rect(screen,"Evidence cylinder",-22,425,300,295);
        var rim=Fill(cylinder,22,22,256,256,Pink);rim.sprite=Circle();
        var body=Fill(cylinder,26,26,248,248,new Color32(46,47,65,255));body.sprite=Circle();
        var hub=Fill(cylinder,132,132,36,36,Ink);hub.sprite=Circle();
        for(int i=0;i<6;i++){
            chambers[i]=Fill(cylinder,0,0,50,50,Ink);chambers[i].sprite=Circle();
            if(i<3){int n=i;chambers[i].raycastTarget=true;var b=chambers[i].gameObject.AddComponent<Button>();b.onClick.AddListener(()=>SelectEvidence(n));chamberNumbers[i]=Label(chambers[i].transform,(i+1).ToString(),0,0,50,50,21,Gold);chamberNumbers[i].alignment=TextAnchor.MiddleCenter;}
        }
        Label(cylinder,"▼",137,-1,30,30,25,Gold);Label(cylinder,"+",136,129,40,40,32,Pink);
    }
    Sprite circle;
    Sprite Circle(){
        if(circle)return circle;var tex=new Texture2D(64,64,TextureFormat.RGBA32,false);for(int y=0;y<64;y++)for(int x=0;x<64;x++){float d=Vector2.Distance(new Vector2(x+.5f,y+.5f),new Vector2(32,32));tex.SetPixel(x,y,new Color(1,1,1,Mathf.Clamp01(32-d)));}tex.Apply();circle=Sprite.Create(tex,new Rect(0,0,64,64),new Vector2(.5f,.5f),64);return circle;
    }
    void ShowDebate(){
        State=Phase.Debate;Clear();Label(screen,"NONSTOP DEBATE",35,24,850,40,23,Pink);hud=Label(screen,"",850,24,410,70,20,Gold);
        timer=Label(screen,"",1080,108,185,45,28,Pink);focus=Label(screen,"",1000,160,250,35,18,Gold);feedback=Label(screen,"",350,420,870,70,29,Pink);
        BuildCylinder();Label(screen,"LOADED TRUTH BULLET",260,559,650,30,16,Pink);Fill(screen,260,597,440,44,new Color32(64,50,43,255));Fill(screen,260,597,7,44,Gold);
        loaded=Label(screen,TrialCase.Bullets[Selected],279,600,500,40,25,Gold);Fill(screen,250,642,790,70,new Color(.04f,.04f,.07f,.8f));evidence=Label(screen,TrialCase.Evidence(Selected,Culprit),260,649,770,65,17);
        Fill(screen,250,518,960,29,new Color(.04f,.04f,.07f,.7f));Label(screen,"Q/E or WHEEL: load   SHIFT: focus   TAB: evidence   RIGHT CLICK: silence noise",260,523,980,35,16);
        reticle=Label(screen,"+",0,0,35,35,32,Gold);panelIndex=0;spin=desiredSpin=-Selected*60;SpawnPanel();
    }
    public void SelectEvidence(int index){
        if(index<0||index>=3||State!=Phase.Debate||loadTime>0||fireCooldown>0)return;
        if(Selected!=index)loadTime=.22f;Selected=index;desiredSpin=-index*60;loaded.text=TrialCase.Bullets[index];evidence.text=TrialCase.Evidence(index,Culprit);
    }
    void SpawnPanel(){
        if(phrase)Destroy(phrase.gameObject);if(noise)Destroy(noise.gameObject);weak=null;noise=null;noiseRect=null;noiseCleared=false;noiseTime=0;
        var panels=TrialCase.Debates[Round];panel=panels[panelIndex%panels.Length];panelIndex++;panelTime=0;
        int actor=panel.role==0?Culprit:(Culprit+(panel.role==1?2:4))%7;cameraRig.Set(MainCamera,Actors[actor],panel.shot,panel.duration);
        var old=screen.Find("Speaker");if(old)Destroy(old.gameObject);var speaker=Label(screen,TrialCase.Names[actor]+" / "+TrialCase.Jobs[actor],40,108,900,50,25);speaker.name="Speaker";
        phrase=Rect(screen,"Statement",300,240,820,95);
        if(panel.IsWeak){
            float before=Measure(panel.prefix,30),middle=Measure(panel.weak,30),after=Measure(panel.suffix,30);float x=Mathf.Max(0,(820-before-middle-after)/2);
            Label(phrase,panel.prefix,x,20,before+3,50,30);weak=Label(phrase,panel.weak,x+before,20,middle+4,50,30,Gold).rectTransform;Fill(weak,0,39,middle,2,Gold);Label(phrase,panel.suffix,x+before+middle,20,after+8,50,30);
        }else Label(phrase,panel.text,0,20,820,65,30);
        if(!string.IsNullOrEmpty(panel.noise)){
            noise=Label(screen,panel.noise,480,265,480,65,28,new Color32(190,150,212,255));noiseRect=noise.rectTransform;var outline=noise.gameObject.AddComponent<Outline>();outline.effectColor=Ink;outline.effectDistance=new Vector2(4,-4);
        }
        if(reticle)reticle.transform.SetAsLastSibling();
    }
    float Measure(string value,int size){return new GUIStyle{font=font,fontSize=size}.CalcSize(new GUIContent(value)).x;}
    bool Contains(RectTransform r,Vector2 point){if(!r)return false;Vector2 p;RectTransformUtility.ScreenPointToLocalPointInRectangle(r,point,null,out p);return r.rect.Contains(p);}
    Vector2 CanvasPoint(Vector2 mouse){Vector2 p;RectTransformUtility.ScreenPointToLocalPointInRectangle(screen,mouse,null,out p);return new Vector2(p.x,-p.y);}
    public void Silence(Vector2 point){
        if(State!=Phase.Debate||record||silenceCooldown>0)return;silenceCooldown=.25f;
        if(noise&&!noiseCleared&&Contains(noiseRect,point)){noiseCleared=true;remaining=Mathf.Min(120,remaining+5);noise.gameObject.SetActive(false);Feedback("NOISE CLEARED  +5 SEC");Shatter(CanvasPoint(point),new Color32(190,150,212,255));}
        else{remaining=Mathf.Max(0,remaining-3);Feedback("SILENCER MISSED  -3 SEC");}
    }
    void Feedback(string value){if(feedback)feedback.text=value;feedbackTime=1.5f;}
    public void Fire(Vector2 point){if(State!=Phase.Debate||record||loadTime>0||fireCooldown>0)return;fireCooldown=.65f;shots++;recoil=1;if(!muted)sfx.PlayOneShot(shotClip);shotRoutine=StartCoroutine(ResolveShot(point));}
    IEnumerator ResolveShot(Vector2 point){
        int token=sequence,bullet=Selected,answer=panel.answer;bool hit=Contains(weak,point),hitStatement=Contains(phrase,point),blocked=noise&&!noiseCleared&&Contains(noiseRect,point);
        Vector2 end=CanvasPoint(point),start=new Vector2(128,466);var shot=Label(effects,TrialCase.Bullets[bullet],start.x,start.y,500,50,28,Gold);float t=0;loaded.color=new Color(Gold.r,Gold.g,Gold.b,.3f);
        while(t<.22f){t+=Time.deltaTime;if(token!=sequence)yield break;float a=Mathf.Clamp01(t/.22f);shot.rectTransform.anchoredPosition=Vector2.Lerp(new Vector2(start.x,-start.y),new Vector2(end.x-70,-end.y),a*a);shot.transform.localScale=Vector3.one*Mathf.Lerp(1.1f,.45f,a);yield return null;}
        Destroy(shot.gameObject);if(token!=sequence||State!=Phase.Debate)yield break;loaded.color=Gold;
        if(blocked){remaining=Mathf.Max(0,remaining-15);Feedback("BLOCKED — RIGHT-CLICK THE WHITE NOISE");yield break;}
        if(hit&&TrialCase.Correct(answer,bullet)){
            hits++;Score+=100;Round++;State=Phase.Break;phrase.gameObject.SetActive(false);if(noise)noise.gameObject.SetActive(false);Shatter(end,Gold);Feedback("BREAK! +100");
            var counter=Label(effects,"THAT DOESN'T ADD UP!",170,215,1100,110,60,Pink);counter.gameObject.AddComponent<Outline>().effectDistance=new Vector2(4,-4);
            yield return new WaitForSeconds(1.2f);if(token==sequence)ShowDialogue(true);
        }else{if(hitStatement)Confidence--;Feedback(hit?"WRONG EVIDENCE":hitStatement?"AIM AT THE GOLD WEAK POINT":"MISS");if(Confidence<=0)ShowResult(false,"Your argument fell apart. Review the evidence before firing.");}
    }
    void Shatter(Vector2 point,Color color){for(int i=0;i<14;i++){var shard=Fill(effects,point.x,point.y,UnityEngine.Random.Range(5,17),UnityEngine.Random.Range(3,10),color);StartCoroutine(FlyShard(shard,UnityEngine.Random.insideUnitCircle*210));}}
    IEnumerator FlyShard(Image shard,Vector2 velocity){float t=0;while(t<.5f&&shard){t+=Time.deltaTime;shard.rectTransform.anchoredPosition+=velocity*Time.deltaTime*2;var c=shard.color;c.a=1-t/.5f;shard.color=c;yield return null;}if(shard)Destroy(shard.gameObject);}
    void ToggleRecord(){
        if(State!=Phase.Debate)return;if(record){Destroy(record.gameObject);record=null;return;}
        record=Rect(screen,"Court Record",0,0,1280,720);var shade=Fill(record,0,0,1280,720,new Color(.03f,.03f,.06f,.98f));shade.raycastTarget=true;Label(record,"COURT RECORD",90,60,1000,90,52,Pink);
        for(int i=0;i<3;i++){int n=i;Button(record,TrialCase.Bullets[i],90,180+i*135,280,64,()=>{SelectEvidence(n);ToggleRecord();});Label(record,TrialCase.Evidence(i,Culprit),405,180+i*135,760,100,23);}
        Button(record,"RETURN TO DEBATE / TAB",775,620,410,55,ToggleRecord);
    }
    void ShowVerdict(){State=Phase.Verdict;Clear();Fill(screen,0,0,1280,720,new Color(.04f,.04f,.08f,.94f));Label(screen,"FINAL VERDICT",70,72,1100,85,56,Pink);Label(screen,"Whose key opened the archive? Whose gold cuff matches the fiber?",74,175,1100,70,25);
        for(int i=0;i<7;i++){int n=i;Button(screen,TrialCase.Names[i]+"\n"+TrialCase.Jobs[i],74+i%4*288,290+i/4*124,265,102,()=>Vote(n));}}
    public void Vote(int suspect){if(State!=Phase.Verdict)return;bool won=suspect==Culprit;if(won)Score+=Confidence*50;ShowResult(won,TrialCase.Names[Culprit]+" took the seal. Their key record and gold fiber exposed the lie about a power cut.");}
    void ShowResult(bool won,string explanation){State=Phase.Result;Clear();Fill(screen,0,0,1280,720,new Color(.035f,.04f,.07f,.95f));Label(screen,won?"CASE CLOSED":"TRIAL FAILED",95,125,1100,100,70,won?Gold:Pink);Label(screen,explanation,100,266,1040,110,27);Label(screen,"SCORE "+Score+"   •   CONTRADICTIONS "+Round+"/3   •   ACCURACY "+Mathf.RoundToInt(100f*hits/Mathf.Max(shots,1))+"%",100,400,1050,55,23,Gold);Button(screen,"RETRY CASE",100,520,300,65,StartCase);Button(screen,"MAIN MENU",425,520,300,65,ShowMenu);Button(screen,"QUIT",750,520,210,65,()=>Application.Quit());}
    void Update(){
        float dt=Time.deltaTime;fireCooldown=Mathf.Max(0,fireCooldown-dt);silenceCooldown=Mathf.Max(0,silenceCooldown-dt);loadTime=Mathf.Max(0,loadTime-dt);feedbackTime=Mathf.Max(0,feedbackTime-dt);recoil=Mathf.Max(0,recoil-dt*5);
        if(!MainCamera||!screen)return;
        if(Input.GetKeyDown(KeyCode.Escape))ShowMenu();
        if(Input.GetKeyDown(KeyCode.M)){muted=!muted;music.mute=muted;}
        if(Input.GetKeyDown(KeyCode.F11))Screen.fullScreen=!Screen.fullScreen;
        if(State==Phase.Dialogue||State==Phase.Reasoning){cameraRig.Step(dt);if(Input.GetKeyDown(KeyCode.Space)||Input.GetKeyDown(KeyCode.Return))NextDialogue();}
        else if(State==Phase.Menu||State==Phase.Intro||State==Phase.Verdict||State==Phase.Result){orbit+=dt*.06f;MainCamera.transform.position=new Vector3(Mathf.Sin(orbit)*6.5f,4.2f,Mathf.Cos(orbit)*6.5f);MainCamera.transform.LookAt(new Vector3(-Mathf.Sin(orbit)*6,1.25f,-Mathf.Cos(orbit)*6));}
        if(State!=Phase.Debate&&State!=Phase.Break)return;
        spin=Mathf.LerpAngle(spin,desiredSpin,Mathf.Min(1,dt*12));if(cylinder){cylinder.anchoredPosition=new Vector2(-22-recoil*9,-425-recoil*6);for(int i=0;i<6;i++){float a=(-90+i*60+spin)*Mathf.Deg2Rad;chambers[i].rectTransform.anchoredPosition=new Vector2(125+Mathf.Cos(a)*75,-125-Mathf.Sin(a)*75);chambers[i].color=i==Selected?Gold:Ink;if(i<3)chamberNumbers[i].color=i==Selected?Ink:Gold;}}
        if(State!=Phase.Debate)return;
        if(Input.GetKeyDown(KeyCode.Tab))ToggleRecord();
        if(record)return;
        if(Input.GetKeyDown(KeyCode.Alpha1))SelectEvidence(0);if(Input.GetKeyDown(KeyCode.Alpha2))SelectEvidence(1);if(Input.GetKeyDown(KeyCode.Alpha3))SelectEvidence(2);
        if(Input.GetKeyDown(KeyCode.Q)||Input.mouseScrollDelta.y>0)SelectEvidence((Selected+2)%3);if(Input.GetKeyDown(KeyCode.E)||Input.mouseScrollDelta.y<0)SelectEvidence((Selected+1)%3);
        bool focusing=(Input.GetKey(KeyCode.LeftShift)||Input.GetKey(KeyCode.RightShift))&&focusAmount>.05f;float speed=focusing?.28f:1;focusAmount=focusing?Mathf.Max(0,focusAmount-dt):Mathf.Min(6,focusAmount+dt*.4f);remaining=Mathf.Max(0,remaining-dt);
        panelTime+=dt*speed;cameraRig.Step(dt*speed);if(panelTime>=panel.duration)SpawnPanel();
        float t=Mathf.Clamp01(panelTime/panel.duration);phrase.anchoredPosition=new Vector2(Mathf.Lerp(300,160,t),-Mathf.Lerp(240,295,t));
        if(noise&&!noiseCleared){noiseTime+=dt*speed;noiseRect.anchoredPosition=phrase.anchoredPosition+new Vector2(180+Mathf.Sin(noiseTime*1.5f)*90,-23);}
        if(hud)hud.text="CONFIDENCE "+Confidence+"/5\nCONTRADICTIONS "+Round+"/3";if(timer)timer.text=((int)remaining/60).ToString("00")+":"+((int)remaining%60).ToString("00");if(focus)focus.text="FOCUS "+Mathf.RoundToInt(focusAmount*100/6)+"%";
        if(feedbackTime<=0&&feedback)feedback.text="";
        Vector2 pointer=Input.mousePosition,canvasPoint=CanvasPoint(pointer);if(reticle){reticle.rectTransform.anchoredPosition=new Vector2(canvasPoint.x-12,-canvasPoint.y+12);reticle.color=Contains(weak,pointer)?Pink:Gold;}
        if(remaining<=0){ShowResult(false,"Time ran out. Review the evidence and find the gold weak point.");return;}
        bool uiBlocked=EventSystem.current&&EventSystem.current.IsPointerOverGameObject();if(!uiBlocked){if(Input.GetMouseButtonDown(0))Fire(pointer);if(Input.GetMouseButtonDown(1))Silence(pointer);}
    }
    public IEnumerator SmokeTest(){
        yield return null;StartCase();dialogueIndex=2;NextDialogue();yield return new WaitForSeconds(3.2f);
        if(State!=Phase.Debate)throw new Exception("Intro failed");
        for(int stage=0;stage<3;stage++){
            for(int i=0;i<4&&!panel.IsWeak;i++)SpawnPanel();yield return new WaitForSeconds(.3f);noiseCleared=true;if(noise)noise.gameObject.SetActive(false);SelectEvidence(stage);yield return new WaitForSeconds(.3f);
            Vector3[] corners=new Vector3[4];weak.GetWorldCorners(corners);Fire((corners[0]+corners[2])/2);yield return new WaitForSeconds(1.6f);
            if(State!=Phase.Reasoning)throw new Exception("Contradiction failed "+stage);NextDialogue();if(stage<2)yield return new WaitForSeconds(3.2f);
        }
        if(State!=Phase.Verdict)throw new Exception("Verdict missing");Vote(Culprit);if(State!=Phase.Result||Score!=550)throw new Exception("Score incorrect");Debug.Log("UNITY TRIAL SMOKE PASS");Application.Quit(0);
    }
    void OnDestroy(){if(portraitTexture){portraitTexture.Release();Destroy(portraitTexture);}if(circle){Destroy(circle.texture);Destroy(circle);}if(shotClip)Destroy(shotClip);}
}
}
