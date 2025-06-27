#!/usr/bin/env python3
"""
Stunning Trading Icon Generator - Focused on creating the perfect icon
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

class StunningIconGenerator:
    def __init__(self):
        self.base_url = "https://api.replicate.com/v1/predictions"
        self.output_dir = "stunning_icons"
        os.makedirs(self.output_dir, exist_ok=True)
        
    def generate_premium_trading_icon(self, concept_name, prompt):
        """Generate a single premium trading icon"""
        
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
        
        return self._make_request(payload, concept_name)
    
    def generate_all_concepts(self):
        """Generate multiple concept variations"""
        print("🎨 Generating STUNNING Trading Icons")
        print("====================================")
        
        concepts = {
            "bull_crystal": "3D crystalline bull head, emerald green (#00D4AA) crystal material, faceted gem-like surfaces, premium luxury feel, dramatic lighting, white background, mobile app icon, ultra realistic, 8K quality",
            
            "rising_arrow_3d": "Elegant 3D upward arrow, sleek metallic teal (#00D4AA) finish, floating above subtle shadow, minimalist luxury design, perfect proportions, white background, professional mobile icon",
            
            "chart_mountain": "Stylized mountain silhouette formed by ascending chart bars, gradient from dark teal to bright teal (#00D4AA), geometric precision, modern fintech branding, white background",
            
            "golden_bull_minimal": "Ultra-minimalist golden bull silhouette, single teal (#00D4AA) accent line, sophisticated negative space, luxury trading symbol, pristine white background, perfect mobile icon",
            
            "data_orb": "Glowing transparent sphere containing rising chart pattern, inner teal (#00D4AA) luminescence, floating particles, high-tech elegance, white background, premium mobile icon",
            
            "geometric_growth": "Abstract geometric pattern suggesting upward movement, interlocking teal (#00D4AA) shapes, modern architectural style, clean lines, sophisticated design, white background"
        }
        
        icons_generated = []
        
        for concept_name, prompt in concepts.items():
            print(f"\n🚀 Creating: {concept_name}")
            result = self.generate_premium_trading_icon(concept_name, prompt)
            if result:
                icons_generated.extend(result)
            time.sleep(2)  # Rate limiting
        
        return icons_generated
    
    def _make_request(self, payload, filename_prefix):
        """Make API request and handle response"""
        try:
            response = requests.post(self.base_url, headers=HEADERS, json=payload)
            response.raise_for_status()
            
            prediction_data = response.json()
            prediction_id = prediction_data['id']
            
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
                    if attempt % 5 == 0:  # Print every 5th attempt
                        print(f"⏳ {filename_prefix} - Processing... ({attempt + 1}/{max_attempts})")
                    time.sleep(2)
                    
                else:
                    print(f"🔄 {filename_prefix} - Status: {status}")
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
    """Generate stunning trading icons"""
    print("💎 STUNNING Trading Icon Generator")
    print("==================================")
    print("🎯 Creating professional-grade icons for your trading app...")
    
    generator = StunningIconGenerator()
    icons = generator.generate_all_concepts()
    
    if icons:
        print(f"\n✨ Successfully generated {len(icons)} stunning icon concepts!")
        print(f"📁 Check the '{generator.output_dir}' directory")
        print("\n📱 Integration steps:")
        print("1. Choose your favorite concept")
        print("2. Copy to: trading_tip_generator/assets/images/premium_ai_icon.png")
        print("3. Hot reload the app to see the new icon")
        print("\n💡 Each concept offers a unique visual approach to trading/finance")
    else:
        print("\n❌ Generation failed. Please check your Replicate API token.")

if __name__ == "__main__":
    main() 