using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using CLIPSNet;
using InteractiveCLIPS;

using System.Timers;
using System.Threading;
using System.Runtime.InteropServices;

using FACELibrary;
using YarpManagerCS;

namespace AttentionModule
{
    [ModuleDefinition(ClpFileName = "init.clp")]
    public class AttentionModuleDef : Module
    {
        private YarpPort lookAtPort;
        private YarpPort expressionPort;
        private YarpPort SceneReceiverPort;
        private Scene sceneData;
        private string received;
        private Winner WinnerSub;
        private FaceExpression exp;

        private System.Timers.Timer receiveDataTimer = new System.Timers.Timer();
        private Thread _worker;

        public static CLIPSNet.UserFunction uf_lookat;
        public static CLIPSNet.UserFunction uf_makeexp;
        delegate CLIPSNet.DataTypes.Integer lookAtDelegate(CLIPSNet.DataTypes.Integer id, CLIPSNet.DataTypes.Double x, CLIPSNet.DataTypes.Double y);
        delegate CLIPSNet.DataTypes.Integer makeExpressionDelegate(CLIPSNet.DataTypes.Double v, CLIPSNet.DataTypes.Double a);

        private System.Timers.Timer checkPortTimer = new System.Timers.Timer();
        private bool sceneAnalyserPortExists = false;
        private bool sceneAnalyserConnectionExists = false;


        protected override void Init()
        {
            uf_lookat = new CLIPSNet.UserFunction(ClipsEnv, new lookAtDelegate(FunLookAt), "fun_lookat");
            uf_makeexp = new CLIPSNet.UserFunction(ClipsEnv, new makeExpressionDelegate(FunMakeExp), "fun_makeexp");

            InitYarp();

            receiveDataTimer.Interval = 300;
            receiveDataTimer.Elapsed += new ElapsedEventHandler(receiveDataTimer_Elapsed);


            //checkPortTimer.Interval = 1000;
            //checkPortTimer.Elapsed += new ElapsedEventHandler(checkPortTimer_Elapsed);
            //checkPortTimer.Start();

            //_worker = new Thread(Work);
            //_worker.Start();

            //LoadFromFile();
        }

        private void InitYarp()
        {
            lookAtPort = new YarpPort();
            lookAtPort.openSender("/AttentionModule/LookAt:o");

            expressionPort = new YarpPort();
            expressionPort.openSender("/SenderAttentionModuleExp");

            SceneReceiverPort = new YarpPort();
            sceneAnalyserPortExists = SceneReceiverPort.PortExists("/SceneAnalyzer/MetaSceneXML:o");
            if (sceneAnalyserPortExists)
            {
                SceneReceiverPort.openReceiver("/SceneAnalyzer/MetaSceneXML:o", "/InteractiveCLIPS/MetaSceneXML:i");
                System.Diagnostics.Debug.WriteLine("Connection created!");
                sceneAnalyserConnectionExists = true;
                receiveDataTimer.Start();
            }
            else 
            {

                System.Diagnostics.Debug.WriteLine("Connection NOT created! /SceneAnalyzer/MetaSceneXML:o port does not exist!");

            }

           

           
        }

        //DOBBIAMO FARE IN MODO CHE ANCHE QUESTO MODULO UNA VOLTA CHIUSO CHIAMI LA DISCONNECT SULLA PORTA YARP UTILIZZATA

        [ClipsAction("fun_lookat")]
        public CLIPSNet.DataTypes.Integer FunLookAt(CLIPSNet.DataTypes.Integer id, CLIPSNet.DataTypes.Double xCoord, CLIPSNet.DataTypes.Double yCoord)
        {
            //System.Diagnostics.Debug.WriteLine("WINNER: " + (int)id.Value + " x: " + ((float)xCoord.Value) + " - y: " + ((float)yCoord.Value));
             WinnerSub = new Winner();
                        
            if(id.Value!=0)
            {
                foreach (Subject subject in sceneData.Subjects)
                {
                    if(id.Value==subject.idKinect)
                    {
                        float Xmax = subject.head.Z * (float)Math.Tan((57.00/180.00)*Math.PI);
                        float X = ((subject.head.X / Xmax)/2)+(float)0.5;

                        float Ymax = subject.head.Z * (float)Math.Tan((43.00 / 180.00) * Math.PI);
                        float Y = ((subject.head.Y / Ymax) / 2) + (float)0.5;

                        WinnerSub.id = (int)id.Value;
                        WinnerSub.spinX =  X;
                        WinnerSub.spinY = Y;
                    }
                }

                
            }         
            else
            {
                WinnerSub.id = (int)id.Value;
                WinnerSub.spinX =  (float)xCoord.Value;
                WinnerSub.spinY = (float)yCoord.Value;
            }
        

           
           

            string WinnerXml = ComUtils.XmlUtils.Serialize<Winner>(WinnerSub);
            lookAtPort.sendData(WinnerXml);

            return id;
        }

        int n = 0;
        [ClipsAction("fun_makeexp")]
        public CLIPSNet.DataTypes.Integer FunMakeExp(CLIPSNet.DataTypes.Double v, CLIPSNet.DataTypes.Double a)
        {
            //System.Diagnostics.Debug.WriteLine("ECS -> Valence = " + v.ToString() + " - Arousal = " + a.ToString());

            FaceExpression exp = new FaceExpression();
            exp.valence = (float)v.Value;
            exp.arousal = (float)a.Value;

            string expressionXml = ComUtils.XmlUtils.Serialize<FaceExpression>(exp);
            expressionPort.sendData(expressionXml);

            return new CLIPSNet.DataTypes.Integer(0);
        }

        #region Yarp
     

        /* Asserts managed by a timer */
        void receiveDataTimer_Elapsed(object sender, ElapsedEventArgs e)
        {
            SceneReceiverPort.receivedData(out received);
            if (received != null && received != "")
            {

                System.Threading.Thread t1 = new System.Threading.Thread(
                    delegate()
                    {
                        //System.Diagnostics.Debug.WriteLine(received);
                        sceneData = ComUtils.XmlUtils.Deserialize<Scene>(received);
                        foreach (Subject subject in sceneData.Subjects)
                        {
                            AssertTemplate(typeof(Subject), subject, (subject.idKinect).ToString());
                            //if(subject.id != 0)
                            //    System.Diagnostics.Debug.WriteLine("Found subject "+subject.id);
                        }
                       
                            AssertTemplate(typeof(Surroundings), sceneData.Environment, "0");
                            //System.Diagnostics.Debug.WriteLine("Found surroundings " +sceneData.Environment);
                           
                        
                    });
                t1.Priority = ThreadPriority.Lowest;
                t1.Start();

            }
        }
     
        #endregion
        
      
    }
}


