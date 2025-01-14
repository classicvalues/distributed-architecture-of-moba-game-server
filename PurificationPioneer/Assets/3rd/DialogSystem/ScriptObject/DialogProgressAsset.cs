using System;
using System.Collections.Generic;
using DialogSystem.Model;
using ReadyGamerOne.Common;
using UnityEngine;

namespace DialogSystem.ScriptObject
{
    [ScriptableSingletonInfo("DialogProgressPoints")]
    public class DialogProgressAsset : ScriptableSingleton<DialogProgressAsset>
    {
        public event Action<float> onProgressChanged; 
        
        public List<DialogProgressPoint> DialogProgressPoints=new List<DialogProgressPoint>();
        [SerializeField] private float currentProgress = 0f;

        public void SetProgress(float value, bool broadEvent = false)
        {
            currentProgress = value;
            if (broadEvent)
                onProgressChanged?.Invoke(currentProgress);
        }
        public float CurrentProgress
        {
            get { return currentProgress; }
            internal set
            {
                currentProgress = value;
                onProgressChanged?.Invoke(value);
            }
        }
    }
}