using UnityEngine;

namespace PurificationPioneer.Paint
{
    public class Paintable : MonoBehaviour {
        const int TEXTURE_SIZE = 1024;
    
        public float extendsIslandOffset = 1;
    
        RenderTexture extendIslandsRenderTexture;
        RenderTexture uvIslandsRenderTexture;
        RenderTexture maskRenderTexture;
        RenderTexture supportTexture;
        
        Renderer rend;
    
        int maskTextureID = Shader.PropertyToID("_MaskTexture");
    
        public RenderTexture getMask() => maskRenderTexture;
        public RenderTexture getUVIslands() => uvIslandsRenderTexture;
        public RenderTexture getExtend() => extendIslandsRenderTexture;
        public RenderTexture getSupport() => supportTexture;
        public Renderer getRenderer() => rend;
    
        void Start() {
            maskRenderTexture = new RenderTexture(TEXTURE_SIZE, TEXTURE_SIZE, 0)
            {
                filterMode = FilterMode.Bilinear
            };
    
            extendIslandsRenderTexture = new RenderTexture(TEXTURE_SIZE, TEXTURE_SIZE, 0)
            {
                filterMode = FilterMode.Bilinear
            };
    
            uvIslandsRenderTexture = new RenderTexture(TEXTURE_SIZE, TEXTURE_SIZE, 0)
            {
                filterMode = FilterMode.Bilinear
            };
    
            supportTexture = new RenderTexture(TEXTURE_SIZE, TEXTURE_SIZE, 0)
            {
                filterMode = FilterMode.Bilinear
            };
    
            rend = GetComponent<Renderer>();
            rend.material.SetTexture(maskTextureID, extendIslandsRenderTexture);
    
            PaintManager.Instance.initTextures(this);
        }
    
        void OnDisable(){
            maskRenderTexture.Release();
            uvIslandsRenderTexture.Release();
            extendIslandsRenderTexture.Release();
            supportTexture.Release();
        }
    }
}
