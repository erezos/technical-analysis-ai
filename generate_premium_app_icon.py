#!/usr/bin/env python3
"""
Premium AI Analytics Icon Generator
Generate a single, perfect icon for the main app screen
"""

import requests
import os
import time
from datetime import datetime

# Replicate API configuration
REPLICATE_API_TOKEN = os.getenv('REPLICATE_API_TOKEN', 'your_token_here')
HEADERS = {
    'Authorization': f'Bearer {REPLICATE_API_TOKEN}',
    'Content-Type': 'application/json'
}

class PremiumIconGenerator:
    def __init__(self):
        self.base_url = "https://api.replicate.com/v1/predictions"
        self.output_dir = "generated_icons"
        os.makedirs(self.output_dir, exist_ok=True)
        
    def generate_ai_analytics_icon(self, style="modern", variation=1):
        """Generate the perfect AI analytics icon for mobile app"""
        
        prompts = {
            "modern": [
                "3D isometric trading chart icon, ascending candlestick pattern, vibrant teal gradient (#00D4AA), glossy finish, professional fintech style, floating elements, clean white background, mobile app icon, ultra detailed, 4K quality",
                "Minimalist bull market symbol, elegant upward arrow with data points, teal green (#00D4AA) to emerald gradient, sleek modern design, premium fintech branding, white background, mobile optimized icon",
                "Geometric crystal-style analytics cube, faceted surfaces, teal (#00D4AA) gradient lighting, floating financial data streams, modern luxury design, white background, professional mobile app icon",
            ],
            "luxury": [
                "Premium golden bull silhouette with teal accents (#00D4AA), sophisticated gradient, elegant financial symbol, luxury trading app icon, minimal design, white background, high-end fintech branding",
                "Luxury diamond-cut chart icon, multifaceted crystalline structure, gold and teal (#00D4AA) gradient, premium reflection effects, sophisticated trading symbol, white background, mobile app icon",
                "Elegant rising arrow with golden particles, teal (#00D4AA) energy trail, luxury fintech design, premium gradient effects, sophisticated trading icon, clean white background",
            ],
            "tech": [
                "Futuristic holographic trading interface, neon teal (#00D4AA) glow, floating data visualizations, sci-fi financial dashboard, high-tech design, dark to light gradient background, mobile app icon",
                "Digital DNA helix made of financial data, glowing teal (#00D4AA) elements, futuristic trading symbol, tech-forward design, gradient background, professional mobile icon",
                "Cyber grid with rising profit arrow, electric teal (#00D4AA) energy, digital matrix style, futuristic trading icon, high-tech gradient background, mobile optimized",
            ]
        }
        
        selected_prompts = prompts.get(style, prompts["modern"])
        prompt = selected_prompts[variation - 1] if variation <= len(selected_prompts) else selected_prompts[0]
        
        payload = {
            "version": "ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4",  # FLUX Schnell
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
        
        return self._make_request(payload, f"ai_analytics_icon_{style}_v{variation}")
    
    def generate_multiple_variations(self):
        """Generate multiple icon variations for comparison"""
        print("🎨 Generating Premium AI Analytics Icons")
        print("======================================")
        
        icons_generated = []
        
        # Modern style variations
        print("\n🔥 Modern Style Icons...")
        for i in range(1, 4):
            result = self.generate_ai_analytics_icon("modern", i)
            if result:
                icons_generated.extend(result)
            time.sleep(1)  # Rate limiting
        
        # Luxury style variations
        print("\n💎 Luxury Style Icons...")
        for i in range(1, 3):
            result = self.generate_ai_analytics_icon("luxury", i)
            if result:
                icons_generated.extend(result)
            time.sleep(1)
        
        # Tech style variations
        print("\n🚀 Tech Style Icons...")
        for i in range(1, 3):
            result = self.generate_ai_analytics_icon("tech", i)
            if result:
                icons_generated.extend(result)
            time.sleep(1)
        
        return icons_generated
    
    def _make_request(self, payload, filename_prefix):
        """Make API request and handle response"""
        try:
            response = requests.post(self.base_url, headers=HEADERS, json=payload)
            response.raise_for_status()
            
            prediction_data = response.json()
            prediction_id = prediction_data['id']
            
            print(f"🚀 Generating: {filename_prefix}")
            print(f"📊 Prediction ID: {prediction_id}")
            
            return self._poll_prediction(prediction_id, filename_prefix)
            
        except requests.exceptions.RequestException as e:
            print(f"❌ API request failed: {e}")
            return None
    
    def _poll_prediction(self, prediction_id, filename_prefix, max_attempts=60):
        """Poll prediction until completion"""
        url = f"{self.base_url}/{prediction_id}"
        
        for attempt in range(max_attempts):
            try:
                response = requests.get(url, headers=HEADERS)
                response.raise_for_status()
                data = response.json()
                
                status = data.get('status')
                
                if status == 'succeeded':
                    output_urls = data.get('output', [])
                    if output_urls:
                        return self._download_assets(output_urls, filename_prefix)
                    else:
                        print(f"❌ No output URLs found for {filename_prefix}")
                        return None
                        
                elif status == 'failed':
                    error = data.get('error', 'Unknown error')
                    print(f"❌ Generation failed for {filename_prefix}: {error}")
                    return None
                
                elif status in ['starting', 'processing']:
                    print(f"⏳ {filename_prefix} - Status: {status} ({attempt + 1}/{max_attempts})")
                    time.sleep(2)
                    
                else:
                    print(f"🔄 {filename_prefix} - Unknown status: {status}")
                    time.sleep(2)
                    
            except requests.exceptions.RequestException as e:
                print(f"❌ Polling error for {filename_prefix}: {e}")
                time.sleep(2)
        
        print(f"⏰ Timeout waiting for {filename_prefix}")
        return None
    
    def _download_assets(self, urls, filename_prefix):
        """Download generated assets"""
        downloaded_files = []
        
        for i, url in enumerate(urls):
            try:
                response = requests.get(url)
                response.raise_for_status()
                
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"{filename_prefix}_{timestamp}.png"
                filepath = os.path.join(self.output_dir, filename)
                
                with open(filepath, 'wb') as f:
                    f.write(response.content)
                
                downloaded_files.append(filepath)
                print(f"✅ Downloaded: {filepath}")
                
            except requests.exceptions.RequestException as e:
                print(f"❌ Download failed for {url}: {e}")
        
        return downloaded_files

def main():
    """Generate premium AI analytics icon"""
    print("🎯 Premium AI Analytics Icon Generator")
    print("=====================================")
    print("🎨 Creating the perfect icon for your trading app...")
    
    generator = PremiumIconGenerator()
    icons = generator.generate_multiple_variations()
    
    if icons:
        print(f"\n✨ Successfully generated {len(icons)} icon variations!")
        print(f"📁 Check the '{generator.output_dir}' directory")
        print("\n📱 Next steps:")
        print("1. Choose your favorite icon")
        print("2. Add it to: trading_tip_generator/assets/images/")
        print("3. Update the Flutter code to use the new icon")
        print("\n💡 Recommended: Use the 'modern' style for best mobile UX")
    else:
        print("\n❌ No icons generated. Please check your Replicate API token.")

if __name__ == "__main__":
    main() 