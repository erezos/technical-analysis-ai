#!/usr/bin/env python3
"""
AI Trading Assistant Icon Generator - High-tech variations
"""

import requests
import os
import time
from datetime import datetime

REPLICATE_API_TOKEN = os.getenv('REPLICATE_API_TOKEN', 'your_token_here')
HEADERS = {
    'Authorization': f'Bearer {REPLICATE_API_TOKEN}',
    'Content-Type': 'application/json'
}

def generate_ai_icon(concept_name, prompt):
    """Generate an AI trading assistant icon"""
    
    payload = {
        "version": "ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4",
        "input": {
            "prompt": prompt,
            "width": 1024,
            "height": 1024,
            "num_outputs": 1,
            "output_format": "png",
            "guidance_scale": 3.5,
            "num_inference_steps": 4
        }
    }
    
    try:
        response = requests.post("https://api.replicate.com/v1/predictions", 
                               headers=HEADERS, json=payload)
        
        if response.status_code == 201:
            prediction_id = response.json()['id']
            print(f"✅ Started generating {concept_name} icon...")
            
            # Poll for completion
            while True:
                result = requests.get(f"https://api.replicate.com/v1/predictions/{prediction_id}", 
                                    headers=HEADERS)
                
                if result.status_code == 200:
                    data = result.json()
                    
                    if data['status'] == 'succeeded':
                        image_url = data['output'][0]
                        
                        # Download the image
                        img_response = requests.get(image_url)
                        if img_response.status_code == 200:
                            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                            filename = f"ai_trading_icons/{concept_name}_{timestamp}.png"
                            
                            os.makedirs("ai_trading_icons", exist_ok=True)
                            
                            with open(filename, 'wb') as f:
                                f.write(img_response.content)
                            
                            print(f"✅ {concept_name} icon saved: {filename}")
                            return filename
                        break
                    elif data['status'] == 'failed':
                        print(f"❌ Failed to generate {concept_name}: {data.get('error', 'Unknown error')}")
                        break
                    
                    time.sleep(2)
                else:
                    print(f"❌ Error checking status: {result.status_code}")
                    break
                    
    except Exception as e:
        print(f"❌ Error generating {concept_name}: {e}")
    
    return None

def main():
    print("🤖 AI Trading Assistant Icon Generator")
    print("=" * 50)
    
    # Base prompt with 5 variations
    base_prompt = "A high-tech, futuristic app icon for an AI-powered financial trading assistant. The icon should feature a sleek abstract symbol combining a stylized 'A' and 'I' with subtle circuitry patterns and glowing accents. It should convey intelligence, precision, and cutting-edge analysis. The design should have a clean, 3D glass-like aesthetic with a dark background and a vibrant neon glow. Emphasize a tech-savvy and trustworthy look suitable for a modern financial mobile app."
    
    variations = {
        "green_blue_glow": base_prompt + " Focus on green-blue accents with electric blue circuitry patterns.",
        
        "cyan_teal_variant": base_prompt + " Use cyan and teal glowing accents with holographic effects and digital grid patterns.",
        
        "electric_blue": base_prompt + " Emphasize electric blue and white glowing effects with futuristic hexagonal patterns.",
        
        "neon_green": base_prompt + " Feature bright neon green accents with matrix-style digital rain effects and sharp geometric lines.",
        
        "purple_blue": base_prompt + " Use purple-blue gradient glows with neural network patterns and crystalline geometric shapes."
    }
    
    print(f"Generating 5 AI trading assistant icon variations...")
    print()
    
    generated_icons = []
    
    for concept, prompt in variations.items():
        print(f"🔄 Generating: {concept}")
        print(f"📝 Variation: {prompt.split('.')[-1].strip()}")
        
        result = generate_ai_icon(concept, prompt)
        if result:
            generated_icons.append(result)
        
        print()
        time.sleep(1)  # Rate limiting
    
    print("🎉 Generation Complete!")
    print(f"✅ Generated {len(generated_icons)} AI trading assistant icons")
    print(f"📁 Icons saved in: ai_trading_icons/")
    
    if generated_icons:
        print("\n🤖 Your AI Trading Icons:")
        for icon in generated_icons:
            print(f"  • {icon}")

if __name__ == "__main__":
    main()
