#!/usr/bin/env python3
"""
Fintech Mobile App Icon Generator - Crystal Clear Purpose
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

def generate_fintech_icon(concept_name, prompt):
    """Generate a fintech mobile app icon"""
    
    payload = {
        "version": "ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4",
        "input": {
            "prompt": prompt,
            "width": 512,
            "height": 512,
            "num_outputs": 1,
            "output_format": "png",
            "guidance_scale": 3.5,
            "num_inference_steps": 4
        }
    }
    
    try:
        response = requests.post("https://api.replicate.com/v1/predictions", headers=HEADERS, json=payload)
        response.raise_for_status()
        prediction_id = response.json()['id']
        
        print(f"🚀 Generating fintech icon: {concept_name}")
        print(f"📊 ID: {prediction_id}")
        
        # Poll for completion
        for attempt in range(60):
            response = requests.get(f"https://api.replicate.com/v1/predictions/{prediction_id}", headers=HEADERS)
            data = response.json()
            
            if data['status'] == 'succeeded':
                url = data['output'][0]
                response = requests.get(url)
                
                os.makedirs("fintech_icons", exist_ok=True)
                filename = f"fintech_icons/{concept_name}_{datetime.now().strftime('%H%M%S')}.png"
                
                with open(filename, 'wb') as f:
                    f.write(response.content)
                
                print(f"✅ Saved: {filename}")
                return filename
            elif data['status'] == 'failed':
                print(f"❌ Failed: {data.get('error', 'Unknown error')}")
                return None
            
            time.sleep(2)
        
        print("⏰ Timeout")
        return None
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def main():
    print("📱 FINTECH MOBILE APP ICON GENERATOR")
    print("====================================")
    
    # Super specific fintech mobile app icon prompts
    concepts = {
        "trading_bull_icon": "Mobile app icon for trading application: stylized bull head silhouette, teal green (#00D4AA), minimalist design, recognizable at 64px size, iOS/Android app store ready, clean white background, professional fintech branding",
        
        "upward_chart_icon": "Fintech mobile app icon: simple upward trending line chart, bold teal (#00D4AA) color, geometric clean design, clearly visible on phone screen, trading app symbol, white background, app store compliant",
        
        "growth_arrow_icon": "Trading mobile app icon: elegant upward arrow, teal (#00D4AA) gradient, minimal modern design, recognizable at small sizes, financial growth symbol, white background, professional fintech app",
        
        "stock_bar_icon": "Investment app icon for mobile: ascending bar chart pattern, teal (#00D4AA) color scheme, simple geometric design, clear at 64px resolution, trading platform branding, white background",
        
        "diamond_trend_icon": "Premium trading app icon: diamond shape with upward trend line inside, teal (#00D4AA) accent, luxury fintech design, mobile optimized, clear at small sizes, white background"
    }
    
    print("🎯 Creating 5 fintech mobile app icons...")
    
    results = []
    for name, prompt in concepts.items():
        result = generate_fintech_icon(name, prompt)
        if result:
            results.append(result)
        time.sleep(3)  # Rate limiting
    
    print(f"\n✨ Generated {len(results)} fintech mobile icons!")
    print("📱 Each icon is specifically designed for mobile app use")
    print("📁 Check the 'fintech_icons' directory")

if __name__ == "__main__":
    main()
