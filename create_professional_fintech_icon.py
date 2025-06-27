#!/usr/bin/env python3
"""
Professional Fintech Mobile App Icon Generator
Based on industry best practices and design guidelines
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

def generate_professional_icon(concept_name, prompt):
    """Generate a professional fintech mobile app icon"""
    
    payload = {
        "version": "ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4",
        "input": {
            "prompt": prompt,
            "width": 1024,  # Higher resolution for crisp icons
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
                            filename = f"professional_fintech_icons/{concept_name}_{timestamp}.png"
                            
                            os.makedirs("professional_fintech_icons", exist_ok=True)
                            
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
    print("🎨 Professional Fintech Mobile App Icon Generator")
    print("=" * 50)
    
    # Professional fintech icon prompts based on best practices
    icon_concepts = {
        "minimalist_growth": "Mobile app icon for fintech trading application: clean minimalist upward arrow, single teal gradient (#00D4AA to #4ECDC4), white background, iOS app store compliant, recognizable at 64px, flat design style, professional",
        
        "geometric_chart": "Professional fintech mobile app icon: geometric rising bar chart silhouette, bold teal (#00D4AA), minimal clean design, square format with rounded corners, app store ready, financial analytics symbol",
        
        "modern_bull": "Fintech trading app icon: stylized modern bull head silhouette, teal green (#00D4AA), ultra-minimalist design, iOS/Android compliant, recognizable at small sizes, professional financial branding",
        
        "diamond_analytics": "Mobile app icon for AI trading platform: clean diamond shape with upward trend line, teal gradient (#00D4AA), minimalist flat design, white background, premium fintech aesthetic, app store optimized",
        
        "circle_trend": "Professional trading app icon: circular badge with ascending line graph, bold teal (#00D4AA), clean geometric design, financial symbol, mobile optimized, recognizable icon for app stores",
        
        "abstract_growth": "Modern fintech mobile app icon: abstract upward triangle with data points, teal (#00D4AA) and white, minimalist design, iOS guidelines compliant, trading application symbol, clean and professional"
    }
    
    print(f"Generating {len(icon_concepts)} professional fintech icons...")
    print()
    
    generated_icons = []
    
    for concept, prompt in icon_concepts.items():
        print(f"🔄 Generating: {concept}")
        print(f"📝 Prompt: {prompt[:100]}...")
        
        result = generate_professional_icon(concept, prompt)
        if result:
            generated_icons.append(result)
        
        print()
        time.sleep(1)  # Rate limiting
    
    print("🎉 Generation Complete!")
    print(f"✅ Generated {len(generated_icons)} professional fintech icons")
    print(f"📁 Icons saved in: professional_fintech_icons/")
    
    if generated_icons:
        print("\n🏆 Your Professional Icons:")
        for icon in generated_icons:
            print(f"  • {icon}")

if __name__ == "__main__":
    main()
