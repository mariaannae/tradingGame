#!/usr/bin/env python3
"""
Resource Economy Visualization Generator
Generates charts for trading game resource analysis
"""

import json
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from pathlib import Path
from typing import Dict, List, Tuple

# Configuration
SEASONS = ['spring', 'summer', 'fall', 'winter']
MONTHS_PER_SEASON = 3
BIOMES = ['warm', 'coastal', 'cold', 'steppe', 'mountain']

# Color schemes
CATEGORY_COLORS = {
    'food': '#8BC34A',
    'luxury': '#9C27B0',
    'material': '#795548',
    'trade_good': '#FF9800',
    'weapon': '#F44336',
    'crafted': '#2196F3'
}

BIOME_COLORS = {
    'warm': '#FF6B6B',
    'coastal': '#4ECDC4',
    'cold': '#95E1D3',
    'steppe': '#F38181',
    'mountain': '#AA96DA'
}

SEASON_COLORS = {
    'spring': '#7BC96F',
    'summer': '#F9D56E',
    'fall': '#E8997E',
    'winter': '#9ECDEC'
}


def load_resources(filepath: str = 'data/resources.json') -> Dict:
    """Load resources from JSON file"""
    with open(filepath, 'r') as f:
        return json.load(f)


def load_biome_seasons(filepath: str = 'data/biome_seasons.json') -> Dict:
    """Load biome seasonal sequences from JSON file"""
    with open(filepath, 'r') as f:
        return json.load(f)


def calculate_price(resource: Dict, season: str = '', events: List[str] = []) -> float:
    """Calculate resource price with season and event modifiers"""
    base_price = resource['base_price']
    price = base_price
    
    # Apply seasonal modifier
    if season:
        if season in resource.get('favored_season', []):
            price *= 0.9
        else:
            price *= 1.1
    
    # Apply event modifiers
    for event in events:
        if event in resource.get('event_modifiers', {}):
            price *= resource['event_modifiers'][event]
    
    return round(price, 2)


def get_price_range(resource: Dict) -> Tuple[float, float]:
    """Calculate min and max possible prices for a resource"""
    prices = []
    
    # Calculate for all seasons
    for season in SEASONS:
        prices.append(calculate_price(resource, season))
    
    # Calculate with all event modifiers
    event_modifiers = resource.get('event_modifiers', {})
    for event, modifier in event_modifiers.items():
        for season in SEASONS:
            prices.append(calculate_price(resource, season, [event]))
    
    return min(prices), max(prices)


def chart_1_price_overview(resources: Dict, output_dir: Path):
    """Generate Resource Price Overview Chart"""
    print("Generating Chart 1: Resource Price Overview...")
    
    # Sort resources by base price
    sorted_resources = sorted(resources.items(), key=lambda x: x[1]['base_price'])
    names = [name for name, _ in sorted_resources]
    prices = [res['base_price'] for _, res in sorted_resources]
    categories = [res['category'] for _, res in sorted_resources]
    colors = [CATEGORY_COLORS.get(cat, '#888888') for cat in categories]
    
    # Create figure
    fig, ax = plt.subplots(figsize=(12, 10))
    y_pos = np.arange(len(names))
    
    bars = ax.barh(y_pos, prices, color=colors, alpha=0.8, edgecolor='black', linewidth=0.5)
    
    ax.set_yticks(y_pos)
    ax.set_yticklabels(names, fontsize=9)
    ax.set_xlabel('Base Price (Gold)', fontsize=12, fontweight='bold')
    ax.set_title('Resource Price Overview', fontsize=16, fontweight='bold', pad=20)
    ax.grid(axis='x', alpha=0.3, linestyle='--')
    
    # Add value labels
    for i, (bar, price) in enumerate(zip(bars, prices)):
        ax.text(price + 5, bar.get_y() + bar.get_height()/2, 
                f'{int(price)}', va='center', fontsize=8)
    
    # Create legend for categories
    legend_elements = [mpatches.Patch(facecolor=color, edgecolor='black', label=cat.replace('_', ' ').title())
                      for cat, color in CATEGORY_COLORS.items()]
    ax.legend(handles=legend_elements, loc='lower right', fontsize=10)
    
    plt.tight_layout()
    plt.savefig(output_dir / '1_price_overview.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Saved: {output_dir / '1_price_overview.png'}")


def chart_2_seasonal_impact(resources: Dict, output_dir: Path):
    """Generate Seasonal Price Impact Heatmap"""
    print("Generating Chart 2: Seasonal Price Impact...")
    
    # Calculate price multipliers for each resource in each season
    resource_names = list(resources.keys())
    data = np.zeros((len(resource_names), len(SEASONS)))
    
    for i, (name, resource) in enumerate(resources.items()):
        for j, season in enumerate(SEASONS):
            base = resource['base_price']
            seasonal = calculate_price(resource, season)
            data[i, j] = seasonal / base  # Multiplier
    
    # Create heatmap
    fig, ax = plt.subplots(figsize=(10, 14))
    
    im = ax.imshow(data, cmap='RdYlGn_r', aspect='auto', vmin=0.85, vmax=1.15)
    
    # Set ticks and labels
    ax.set_xticks(np.arange(len(SEASONS)))
    ax.set_yticks(np.arange(len(resource_names)))
    ax.set_xticklabels([s.title() for s in SEASONS], fontsize=11, fontweight='bold')
    ax.set_yticklabels(resource_names, fontsize=9)
    
    # Add text annotations
    for i in range(len(resource_names)):
        for j in range(len(SEASONS)):
            text = ax.text(j, i, f'{data[i, j]:.2f}',
                          ha="center", va="center", color="black", fontsize=7)
    
    ax.set_title('Seasonal Price Multipliers by Resource', fontsize=16, fontweight='bold', pad=20)
    
    # Add colorbar
    cbar = plt.colorbar(im, ax=ax)
    cbar.set_label('Price Multiplier', rotation=270, labelpad=20, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(output_dir / '2_seasonal_impact.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Saved: {output_dir / '2_seasonal_impact.png'}")


def chart_3_volatility_analysis(resources: Dict, output_dir: Path):
    """Generate Price Volatility Analysis"""
    print("Generating Chart 3: Price Volatility Analysis...")
    
    # Calculate min/max for each resource
    volatility_data = []
    for name, resource in resources.items():
        min_price, max_price = get_price_range(resource)
        base_price = resource['base_price']
        volatility_data.append({
            'name': name,
            'min': min_price,
            'max': max_price,
            'base': base_price,
            'range': max_price - min_price,
            'category': resource['category']
        })
    
    # Sort by volatility (range)
    volatility_data.sort(key=lambda x: x['range'], reverse=True)
    
    names = [d['name'] for d in volatility_data]
    mins = [d['min'] for d in volatility_data]
    maxs = [d['max'] for d in volatility_data]
    bases = [d['base'] for d in volatility_data]
    colors = [CATEGORY_COLORS.get(d['category'], '#888888') for d in volatility_data]
    
    # Create figure
    fig, ax = plt.subplots(figsize=(14, 10))
    y_pos = np.arange(len(names))
    
    # Plot ranges
    for i, (y, min_p, max_p, base_p, color) in enumerate(zip(y_pos, mins, maxs, bases, colors)):
        ax.plot([min_p, max_p], [y, y], color=color, linewidth=6, alpha=0.6)
        ax.plot(base_p, y, 'o', color='black', markersize=8, markeredgewidth=1.5, 
                markeredgecolor='white', zorder=5)
    
    ax.set_yticks(y_pos)
    ax.set_yticklabels(names, fontsize=9)
    ax.set_xlabel('Price Range (Gold)', fontsize=12, fontweight='bold')
    ax.set_title('Resource Price Volatility\n(Black dot = base price, Line = min to max)',
                 fontsize=16, fontweight='bold', pad=20)
    ax.grid(axis='x', alpha=0.3, linestyle='--')
    
    # Add range labels
    for i, d in enumerate(volatility_data):
        ax.text(d['max'] + 10, i, f"±{int(d['range']/2)}", 
                va='center', fontsize=7, style='italic')
    
    # Legend
    legend_elements = [mpatches.Patch(facecolor=color, edgecolor='black', label=cat.replace('_', ' ').title())
                      for cat, color in CATEGORY_COLORS.items()]
    ax.legend(handles=legend_elements, loc='lower right', fontsize=10)
    
    plt.tight_layout()
    plt.savefig(output_dir / '3_volatility_analysis.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Saved: {output_dir / '3_volatility_analysis.png'}")


def chart_4_event_impact(resources: Dict, output_dir: Path):
    """Generate Event Impact Matrix"""
    print("Generating Chart 4: Event Impact Matrix...")
    
    # Collect all unique events
    all_events = set()
    for resource in resources.values():
        all_events.update(resource.get('event_modifiers', {}).keys())
    all_events = sorted(list(all_events))
    
    if not all_events:
        print("⚠ No events found in resources")
        return
    
    # Create matrix
    resource_names = list(resources.keys())
    data = np.ones((len(resource_names), len(all_events)))  # Default 1.0 (no change)
    
    for i, (name, resource) in enumerate(resources.items()):
        event_mods = resource.get('event_modifiers', {})
        for j, event in enumerate(all_events):
            if event in event_mods:
                data[i, j] = event_mods[event]
    
    # Create heatmap
    fig, ax = plt.subplots(figsize=(14, 12))
    
    im = ax.imshow(data, cmap='RdYlGn_r', aspect='auto', vmin=0.6, vmax=2.2)
    
    # Set ticks
    ax.set_xticks(np.arange(len(all_events)))
    ax.set_yticks(np.arange(len(resource_names)))
    ax.set_xticklabels([e.replace('_', ' ').title() for e in all_events], 
                        rotation=45, ha='right', fontsize=9)
    ax.set_yticklabels(resource_names, fontsize=9)
    
    # Add text annotations
    for i in range(len(resource_names)):
        for j in range(len(all_events)):
            if data[i, j] != 1.0:  # Only show non-neutral values
                text = ax.text(j, i, f'{data[i, j]:.1f}x',
                              ha="center", va="center", color="black", 
                              fontsize=7, fontweight='bold')
    
    ax.set_title('Event Impact on Resource Prices', fontsize=16, fontweight='bold', pad=20)
    
    # Colorbar
    cbar = plt.colorbar(im, ax=ax)
    cbar.set_label('Price Multiplier', rotation=270, labelpad=20, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(output_dir / '4_event_impact.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Saved: {output_dir / '4_event_impact.png'}")


def chart_5_biome_seasonal_timeline(resources: Dict, output_dir: Path):
    """Generate Biome-Specific Seasonal Price Timeline for common resource"""
    print("Generating Chart 5: Biome-Specific Seasonal Timeline...")
    
    # Find most common resource (food with lowest base price)
    food_resources = [(name, res) for name, res in resources.items() 
                      if res['category'] == 'food']
    if not food_resources:
        print("⚠ No food resources found")
        return
    
    # Sort by base price and pick one of the cheaper ones
    food_resources.sort(key=lambda x: x[1]['base_price'])
    resource_name, resource = food_resources[0]  # Cheapest food item
    
    print(f"  Analyzing: {resource_name}")
    
    # Generate 12 months of data
    months = list(range(1, 13))
    month_to_season = {
        1: 'spring', 2: 'spring', 3: 'spring',
        4: 'summer', 5: 'summer', 6: 'summer',
        7: 'fall', 8: 'fall', 9: 'fall',
        10: 'winter', 11: 'winter', 12: 'winter'
    }
    
    # Calculate prices for each biome
    fig, ax = plt.subplots(figsize=(14, 8))
    
    for biome in BIOMES:
        prices = []
        for month in months:
            season = month_to_season[month]
            
            # Check if resource is local to this biome
            is_local = biome in resource.get('local_biomes', [])
            
            # Calculate base seasonal price
            price = calculate_price(resource, season)
            
            # Apply biome penalty if not local (20% markup for example)
            if not is_local:
                price *= 1.2
            
            prices.append(price)
        
        ax.plot(months, prices, marker='o', linewidth=2.5, 
                color=BIOME_COLORS[biome], label=biome.title(), 
                markersize=6, alpha=0.8)
    
    # Styling
    ax.set_xlabel('Month (Turn)', fontsize=12, fontweight='bold')
    ax.set_ylabel('Price (Gold)', fontsize=12, fontweight='bold')
    ax.set_title(f'"{resource_name.title()}" Price Across Biomes\n(3 months per season)',
                 fontsize=16, fontweight='bold', pad=20)
    ax.set_xticks(months)
    ax.grid(True, alpha=0.3, linestyle='--')
    ax.legend(title='Biome', fontsize=11, title_fontsize=12, loc='upper right')
    
    # Add season background shading
    season_starts = [1, 4, 7, 10]
    for i, (start, season) in enumerate(zip(season_starts, SEASONS)):
        ax.axvspan(start, start + 2.99, alpha=0.1, 
                  color=SEASON_COLORS[season], zorder=0)
        # Add season label
        ax.text(start + 1.5, ax.get_ylim()[1] * 0.95, season.title(),
               ha='center', fontsize=10, fontweight='bold', style='italic',
               color=SEASON_COLORS[season])
    
    # Add note about biome locality
    local_biomes = ', '.join([b.title() for b in resource.get('local_biomes', [])])
    ax.text(0.02, 0.02, f'Local to: {local_biomes}',
            transform=ax.transAxes, fontsize=9, style='italic',
            bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    
    plt.tight_layout()
    plt.savefig(output_dir / '5_biome_seasonal_timeline.png', dpi=300, bbox_inches='tight')
    plt.close()
    print(f"✓ Saved: {output_dir / '5_biome_seasonal_timeline.png'}")


def chart_6_city_seasonal_prices(resources: Dict, biome_seasons: Dict, output_dir: Path):
    """Generate seasonal price charts for each city using biome-specific seasonal sequences"""
    print("Generating Chart 6: City-Specific Seasonal Price Charts...")
    
    # Define cities and their biomes (from map_scene.tscn)
    cities = {
        'Draugaholt': 'cold',
        'Yalanga': 'warm',
        'Corvienne': 'coastal',
        'Tenzura': 'steppe',
        'Meiyara': 'warm'
    }
    
    # Generate a color for each resource
    resource_names = list(resources.keys())
    colors = plt.cm.tab20(np.linspace(0, 1, len(resource_names)))
    resource_colors = {name: colors[i] for i, name in enumerate(resource_names)}
    
    for city_name, biome in cities.items():
        print(f"  Generating chart for {city_name} ({biome})...")
        
        # Get the seasonal sequence for this biome
        biome_data = biome_seasons.get(biome, {})
        seasonal_sequence = biome_data.get('sequence', ['spring', 'summer', 'fall', 'winter'])
        
        print(f"    Using seasonal sequence: {seasonal_sequence}")
        
        # Find resources available in this city (those with this biome in local_biomes)
        available_resources = {}
        for res_name, res_data in resources.items():
            if biome in res_data.get('local_biomes', []):
                available_resources[res_name] = res_data
        
        if not available_resources:
            print(f"  ⚠ No resources available in {city_name}")
            continue
        
        # Create the chart
        fig, ax = plt.subplots(figsize=(12, 8))
        
        # Plot price lines for each available resource across all seasons
        # (Resources are available year-round with price multipliers)
        for res_name, res_data in available_resources.items():
            # Create lists for all positions and prices in the seasonal sequence
            plot_positions = []
            plot_prices = []
            
            for pos, season in enumerate(seasonal_sequence):
                price = calculate_price(res_data, season, [])  # No events
                plot_positions.append(pos)
                plot_prices.append(price)
            
            # Plot the line for this resource
            ax.plot(plot_positions, plot_prices, marker='o', linewidth=2.5,
                   color=resource_colors[res_name], label=res_name.replace('-', ' ').title(),
                   markersize=8, alpha=0.8)
        
        # Styling
        ax.set_xlabel('Seasonal Position', fontsize=12, fontweight='bold')
        ax.set_ylabel('Price (Gold)', fontsize=12, fontweight='bold')
        ax.set_title(f'{city_name} - Seasonal Resource Prices\n({biome.title()} Biome: {", ".join([s.title() for s in seasonal_sequence])})',
                    fontsize=16, fontweight='bold', pad=20)
        ax.grid(True, alpha=0.3, linestyle='--')
        
        # Format x-axis with biome-specific seasons
        ax.set_xticks(range(len(seasonal_sequence)))
        ax.set_xticklabels([f"{i+1}. {s.title()}" for i, s in enumerate(seasonal_sequence)], 
                          fontsize=9)
        
        # Legend - place outside plot area if many resources
        num_resources = len(available_resources)
        if num_resources > 12:
            ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=9, ncol=2)
        else:
            ax.legend(loc='best', fontsize=10, ncol=1 if num_resources <= 8 else 2)
        
        plt.tight_layout()
        
        # Save with city name in filename
        filename = f'6_city_{city_name.lower()}_seasonal_prices.png'
        plt.savefig(output_dir / filename, dpi=300, bbox_inches='tight')
        plt.close()
        print(f"  ✓ Saved: {output_dir / filename}")


def main():
    """Main execution function"""
    print("=" * 60)
    print("Resource Economy Visualization Generator")
    print("=" * 60)
    
    # Create output directory
    output_dir = Path('analysis')
    output_dir.mkdir(exist_ok=True)
    print(f"\nOutput directory: {output_dir.absolute()}\n")
    
    # Load resources
    try:
        resources = load_resources()
        print(f"Loaded {len(resources)} resources")
    except FileNotFoundError:
        print("❌ Error: data/resources.json not found!")
        return
    except json.JSONDecodeError:
        print("❌ Error: Invalid JSON in resources.json!")
        return
    
    # Load biome seasonal sequences
    try:
        biome_seasons = load_biome_seasons()
        print(f"Loaded seasonal sequences for {len(biome_seasons)} biomes\n")
    except FileNotFoundError:
        print("❌ Error: data/biome_seasons.json not found!")
        return
    except json.JSONDecodeError:
        print("❌ Error: Invalid JSON in biome_seasons.json!")
        return
    
    # Generate all charts
    try:
        chart_1_price_overview(resources, output_dir)
        chart_2_seasonal_impact(resources, output_dir)
        chart_3_volatility_analysis(resources, output_dir)
        chart_4_event_impact(resources, output_dir)
        # chart_5_biome_seasonal_timeline(resources, output_dir)  # Removed per user request
        chart_6_city_seasonal_prices(resources, biome_seasons, output_dir)
        
        print("\n" + "=" * 60)
        print("✓ All visualizations generated successfully!")
        print("=" * 60)
        print(f"\nView your charts in: {output_dir.absolute()}")
        
    except Exception as e:
        print(f"\n❌ Error generating charts: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
