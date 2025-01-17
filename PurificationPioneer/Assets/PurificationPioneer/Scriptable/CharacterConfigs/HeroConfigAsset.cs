﻿using System.Text;
using PurificationPioneer.Script;
using UnityEngine;
using UnityEngine.Assertions;

namespace PurificationPioneer.Scriptable
{
    [CreateAssetMenu(fileName = "NewCharacterConfig", menuName = "净化先锋/CharacterConfig", order = 0)]
    public class HeroConfigAsset : ScriptableObject
    {
#if UNITY_EDITOR
        [SerializeField] private string 备注;

        [Space]
#endif
        [Header("常规")]
        public int characterId;
        public GameObject prefab;
        public GameObject previewPrefab;
        public Sprite icon;
        public Sprite attackIcon;
        
        [Header("基础数值")]
        public int baseHp;
        public int increaseHp;
        public int baseAttack;
        public int increaseAttack;
        public int baseDefence;
        public int increaseDefence;
        public int basePaintEfficiency;
        public int increasePaintEfficiency;
        public float moveSpeed;
        public float attackSpeed;

        public int trustValue;
        

        public float jumpSpeed = 10;
        //
        // [Header("技能配置")]
        // public SkillConfigAsset firstSkill;
        // public SkillConfigAsset secondSkill;

        [Header("世界观故事")] public string heroName;
        public string[] stroies;
        public override string ToString()
        {
            var sb = new StringBuilder();
            sb.Append($"-----<HeroConfig>-----\n" +
                      $"Name:{heroName}\n" +
                      $"Hp:{baseHp}\n" +
                      $"Attack:{baseAttack}\n" +
                      $"Defence:{baseDefence}\n" +
                      $"PE:{basePaintEfficiency}");
            return sb.ToString();
        }


        public GameObject PreviewPrefab => previewPrefab ? previewPrefab : prefab;


        public IPpController InstantiateAndInitialize(int seatId, Vector3 worldPosition, Transform parent=null)
        {
            Assert.IsTrue(prefab);

            var characterObj = Object.Instantiate(prefab, worldPosition, prefab.transform.rotation, parent);
            Assert.IsTrue(characterObj);
            
            var ppController = characterObj.GetComponent<IPpController>();
            Assert.IsNotNull(ppController);
            
            //init settings
            ppController.InitCharacterController(seatId, this);
            
            return ppController;
        }
    }
}