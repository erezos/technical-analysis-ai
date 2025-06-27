#!/usr/bin/env python3
"""
Premium Trading Assets Generator using AI
Generate custom buttons, icons, backgrounds, and UI elements for fintech apps
"""

import requests
import os
import json
import time
from datetime import datetime

# Replicate API configuration
REPLICATE_API_TOKEN = os.getenv('REPLICATE_API_TOKEN', 'your_token_here')
HEADERS = {
    'Authorization': f'Bearer {REPLICATE_API_TOKEN}',
    'Content-Type': 'application/json'
}

class PremiumTradingAssetsGenerator:
    def __init__(self):
        self.base_url = "https://api.replicate.com/v1/predictions"
        self.output_dir = "generated_trading_assets"
        os.makedirs(self.output_dir, exist_ok=True)
        
    def generate_trading_button(self, style="glassmorphic", color_scheme="green"):
        """Generate premium trading buttons"""
        prompts = {
            "glassmorphic": f"Ultra-modern glassmorphic trading button with {color_scheme} accent, transparent background, subtle glow effect, professional fintech design, 3D depth, clean typography 'BUY', high-end mobile app UI, 4K resolution",
            "neomorphic": f"Sleek neomorphic trading button with {color_scheme} gradient, soft shadows, embossed effect, premium fintech aesthetic, 'SELL' text, mobile-first design, ultra-clean",
            "gradient": f"Premium gradient trading button with {color_scheme} to gold transition, metallic finish, luxury fintech design, 'TRADE' text, professional mobile app interface",
            "holographic": f"Futuristic holographic trading button with {color_scheme} iridescent effect, digital glow, sci-fi fintech design, 'INVEST' text, next-gen mobile UI"
        }
        
        payload = {
            "version": "ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4",  # FLUX Schnell
            "input": {
                "prompt": prompts.get(style, prompts["glassmorphic"]),
                "width": 512,
                "height": 128,
                "num_outputs": 1,
                "output_format": "png",
                "guidance_scale": 3.5,
                "num_inference_steps": 4
            }
        }
        
        return self._make_request(payload, f"button_{style}_{color_scheme}")
    
    def generate_trading_icon(self, icon_type="trending_up", style="modern"):
        """Generate premium trading icons"""
        prompts = {
            "trending_up": f"{style} trending up arrow icon, financial growth symbol, {style} design, clean vector style, professional fintech branding, transparent background, high contrast",
            "trending_down": f"{style} trending down arrow icon, market decline symbol, {style} design, clean vector style, professional fintech branding, transparent background, high contrast",
            "chart": f"{style} financial chart icon, stock market graph, {style} design, clean vector style, professional fintech branding, transparent background, analytical symbol",
            "portfolio": f"{style} investment portfolio icon, diversified assets symbol, {style} design, clean vector style, professional fintech branding, transparent background",
            "analytics": f"{style} financial analytics icon, data visualization symbol, {style} design, clean vector style, professional fintech branding, transparent background"
        }
        
        payload = {
            "version": "ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4",
            "input": {
                "prompt": prompts.get(icon_type, prompts["trending_up"]),
                "width": 256,
                "height": 256,
                "num_outputs": 1,
                "output_format": "png",
                "guidance_scale": 3.5,
                "num_inference_steps": 4
            }
        }
        
        return self._make_request(payload, f"icon_{icon_type}_{style}")
    
    def generate_trading_background(self, mood="bullish", complexity="minimal"):
        """Generate premium trading backgrounds"""
        prompts = {
            "bullish": f"Premium {complexity} trading app background, {mood} market theme, green ascending charts, financial growth patterns, professional fintech design, dark theme, mobile optimized",
            "bearish": f"Premium {complexity} trading app background, {mood} market theme, red descending charts, market decline patterns, professional fintech design, dark theme, mobile optimized",
            "neutral": f"Premium {complexity} trading app background, {mood} market theme, balanced chart patterns, steady market visualization, professional fintech design, dark theme, mobile optimized",
            "luxury": f"Premium {complexity} trading app background, {mood} market theme, gold and black color scheme, luxury fintech design, sophisticated patterns, mobile optimized"
        }
        
        payload = {
            "version": "ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4",
            "input": {
                "prompt": prompts.get(mood, prompts["bullish"]),
                "width": 512,
                "height": 1024,
                "num_outputs": 1,
                "output_format": "png",
                "guidance_scale": 3.5,
                "num_inference_steps": 4
            }
        }
        
        return self._make_request(payload, f"background_{mood}_{complexity}")
    
    def generate_logo_variation(self, company_name="TradingAI", style="modern"):
        """Generate premium logo variations"""
        prompts = {
            "modern": f"Premium modern logo for {company_name}, financial technology branding, clean typography, professional icon, fintech industry, vector style, scalable design",
            "minimalist": f"Ultra-minimalist logo for {company_name}, simple geometric design, financial symbolism, professional branding, clean vector style, timeless design",
            "tech": f"High-tech logo for {company_name}, digital finance theme, futuristic design elements, technology branding, professional fintech identity",
            "luxury": f"Luxury premium logo for {company_name}, sophisticated design, gold and black theme, high-end financial services branding, elegant typography"
        }
        
        payload = {
            "version": "ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4",
            "input": {
                "prompt": prompts.get(style, prompts["modern"]),
                "width": 512,
                "height": 512,
                "num_outputs": 1,
                "output_format": "png",
                "guidance_scale": 3.5,
                "num_inference_steps": 4
            }
        }
        
        return self._make_request(payload, f"logo_{company_name}_{style}")
    
    def generate_card_design(self, card_type="stats", theme="dark"):
        """Generate premium card designs"""
        prompts = {
            "stats": f"Premium {theme} theme statistics card design, financial metrics display, {theme} background, professional fintech UI, clean layout, mobile optimized",
            "portfolio": f"Premium {theme} theme portfolio card design, investment overview display, {theme} background, professional fintech UI, clean layout, mobile optimized",
            "news": f"Premium {theme} theme news card design, financial news display, {theme} background, professional fintech UI, clean layout, mobile optimized",
            "alert": f"Premium {theme} theme alert card design, trading notification display, {theme} background, professional fintech UI, clean layout, mobile optimized"
        }
        
        payload = {
            "version": "ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4",
            "input": {
                "prompt": prompts.get(card_type, prompts["stats"]),
                "width": 512,
                "height": 256,
                "num_outputs": 1,
                "output_format": "png",
                "guidance_scale": 3.5,
                "num_inference_steps": 4
            }
        }
        
        return self._make_request(payload, f"card_{card_type}_{theme}")
    
    def _make_request(self, payload, filename_prefix):
        """Make API request and handle response"""
        try:
            response = requests.post(self.base_url, headers=HEADERS, json=payload)
            response.raise_for_status()
            
            prediction_data = response.json()
            prediction_id = prediction_data['id']
            
            print(f"🚀 Started generation: {filename_prefix}")
            print(f"📊 Prediction ID: {prediction_id}")
            
            # Poll for completion
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
                    print(f"⏳ {filename_prefix} - Status: {status} (attempt {attempt + 1}/{max_attempts})")
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
                filename = f"{filename_prefix}_{timestamp}_{i+1}.png"
                filepath = os.path.join(self.output_dir, filename)
                
                with open(filepath, 'wb') as f:
                    f.write(response.content)
                
                downloaded_files.append(filepath)
                print(f"✅ Downloaded: {filepath}")
                
            except requests.exceptions.RequestException as e:
                print(f"❌ Download failed for {url}: {e}")
        
        return downloaded_files

def main():
    """Generate premium trading assets"""
    print("🎨 Premium Trading Assets Generator")
    print("===================================")
    
    generator = PremiumTradingAssetsGenerator()
    
    # Generate button variations
    print("\n🔘 Generating Premium Buttons...")
    button_styles = ["glassmorphic", "neomorphic", "gradient", "holographic"]
    color_schemes = ["green", "blue", "purple", "gold"]
    
    for style in button_styles[:2]:  # Limit for demo
        for color in color_schemes[:2]:  # Limit for demo
            generator.generate_trading_button(style, color)
            time.sleep(1)  # Rate limiting
    
    # Generate icon variations
    print("\n🎯 Generating Premium Icons...")
    icon_types = ["trending_up", "trending_down", "chart", "portfolio", "analytics"]
    icon_styles = ["modern", "minimalist", "tech"]
    
    for icon_type in icon_types[:3]:  # Limit for demo
        for style in icon_styles[:2]:  # Limit for demo
            generator.generate_trading_icon(icon_type, style)
            time.sleep(1)
    
    # Generate backgrounds
    print("\n🖼️ Generating Premium Backgrounds...")
    moods = ["bullish", "bearish", "neutral", "luxury"]
    complexities = ["minimal", "detailed"]
    
    for mood in moods[:2]:  # Limit for demo
        for complexity in complexities[:1]:  # Limit for demo
            generator.generate_trading_background(mood, complexity)
            time.sleep(1)
    
    # Generate logo variations
    print("\n🏷️ Generating Premium Logos...")
    logo_styles = ["modern", "minimalist", "tech", "luxury"]
    
    for style in logo_styles[:2]:  # Limit for demo
        generator.generate_logo_variation("TradingTipAI", style)
        time.sleep(1)
    
    print("\n✨ Generation complete! Check the 'generated_trading_assets' directory.")
    print("💡 Import these assets into your Flutter app for premium UI elements.")

if __name__ == "__main__":
    main() 