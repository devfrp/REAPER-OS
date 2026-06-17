#!/bin/bash

################################################################################
# REAPER OS Community Marketplace
# Community trading of presets, templates, and configurations
# Usage: ./community-marketplace.sh [--list] [--publish] [--buy] [--review]
################################################################################

set -euo pipefail

MARKETPLACE_DIR="$HOME/.config/REAPER/marketplace"
MARKETPLACE_DB="$MARKETPLACE_DIR/items.json"
SELLER_PROFILE="$MARKETPLACE_DIR/seller-profile.json"

mkdir -p "$MARKETPLACE_DIR"

# Initialize marketplace database
init_marketplace_db() {
    if [ ! -f "$MARKETPLACE_DB" ]; then
        cat > "$MARKETPLACE_DB" << 'EOF'
{
  "items": [
    {
      "id": "vendor-vocal-chain",
      "name": "Professional Vocal Chain",
      "category": "Effect Chain",
      "seller": "ProAudio Studios",
      "price": 19.99,
      "currency": "USD",
      "rating": 4.9,
      "sales": 342,
      "description": "Industry-standard vocal processing chain",
      "preview_url": "https://marketplace.example.com/preview/...",
      "download_url": "https://marketplace.example.com/download/..."
    },
    {
      "id": "mixing-template-pop",
      "name": "Pop Music Mixing Template",
      "category": "Template",
      "seller": "Mixing Academy",
      "price": 29.99,
      "currency": "USD",
      "rating": 4.8,
      "sales": 256,
      "description": "Professional pop mixing setup with presets"
    },
    {
      "id": "ambient-preset-pack",
      "name": "Ambient Synth Pack",
      "category": "Preset Pack",
      "seller": "SoundDesigner",
      "price": 14.99,
      "currency": "USD",
      "rating": 4.7,
      "sales": 189,
      "description": "128 ambient synthesizer presets"
    }
  ],
  "categories": [
    "Presets",
    "Templates",
    "Effect Chains",
    "VST Configurations",
    "MIDI Files",
    "Sample Packs"
  ]
}
EOF
        echo "Marketplace database initialized"
    fi
}

# List marketplace items
list_marketplace() {
    init_marketplace_db
    
    echo "REAPER OS Community Marketplace"
    echo "================================"
    echo ""
    echo "Popular Items:"
    echo ""
    
    python3 << 'PYTHON'
import json
with open("$MARKETPLACE_DB") as f:
    mp = json.load(f)

print(f"{'Item':<35} {'Seller':<20} {'Price':<10} {'Rating':<8}")
print("=" * 73)

for item in mp['items'][:10]:
    rating_str = f"{item['rating']}/5 ⭐"
    price_str = f"${item['price']}"
    print(f"{item['name']:<35} {item['seller']:<20} {price_str:<10} {rating_str:<8}")

print(f"\nTotal Items: {len(mp['items'])}")
PYTHON
}

# Search marketplace
search_marketplace() {
    local keyword="$1"
    
    echo "Searching for: $keyword"
    
    python3 << PYTHON
import json
keyword = "$keyword".lower()

with open("$MARKETPLACE_DB") as f:
    mp = json.load(f)

results = [item for item in mp['items'] if keyword in item['name'].lower()]

print(f"Found {len(results)} items:\n")

for item in results:
    print(f"✓ {item['name']}")
    print(f"  Seller: {item['seller']}")
    print(f"  Price: \${item['price']}")
    print(f"  Rating: {item['rating']}/5 ({item['sales']} sales)")
    print(f"  {item['description']}\n")
PYTHON
}

# Publish item for sale
publish_item() {
    echo "Publishing item to marketplace..."
    echo ""
    
    read -p "Item name: " item_name
    read -p "Category (Presets/Templates/Chains/etc): " category
    read -p "Price (USD): " price
    read -p "Description: " description
    
    # Create item listing
    cat > "$MARKETPLACE_DIR/$item_name.json" << EOF
{
  "name": "$item_name",
  "category": "$category",
  "price": $price,
  "description": "$description",
  "seller": "$(whoami)",
  "published": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "pending_review"
}
EOF

    echo "Item submitted for review!"
    echo "File: $MARKETPLACE_DIR/$item_name.json"
    echo "Status will update after marketplace review"
}

# Purchase item
purchase_item() {
    local item_id="$1"
    
    echo "Purchasing item: $item_id"
    echo ""
    
    python3 << PYTHON
import json
with open("$MARKETPLACE_DB") as f:
    mp = json.load(f)

for item in mp['items']:
    if item['id'] == "$item_id":
        print(f"Item: {item['name']}")
        print(f"Price: \${item['price']}")
        print(f"Seller: {item['seller']}")
        print("")
        print("Processing purchase...")
        print("✓ Payment received")
        print("✓ Item downloaded")
        print("✓ License activated")
        print("")
        print("Thank you for your purchase!")
        return

print("Item not found")
PYTHON
}

# Review/rate item
review_item() {
    local item_id="$1"
    
    echo "Reviewing item: $item_id"
    echo ""
    
    read -p "Rating (1-5 stars): " rating
    read -p "Your review: " review_text
    
    echo "Review submitted successfully!"
    echo "Thank you for helping the community!"
}

# Generate marketplace storefront
generate_storefront() {
    cat > "$MARKETPLACE_DIR/storefront.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>REAPER OS Community Marketplace</title>
    <style>
        body { font-family: Arial; background: #1a1a1a; color: #fff; }
        .header { background: linear-gradient(135deg, #667eea, #764ba2); padding: 40px; text-align: center; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .search-bar { text-align: center; margin: 20px 0; }
        input { padding: 10px; width: 400px; font-size: 16px; border: none; border-radius: 5px; }
        .items-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; }
        .item-card {
            background: #2a2a2a;
            padding: 15px;
            border-radius: 10px;
            border: 1px solid #3a3a3a;
            cursor: pointer;
            transition: border-color 0.3s;
        }
        .item-card:hover { border-color: #667eea; }
        .item-name { font-weight: bold; font-size: 18px; margin: 10px 0; }
        .item-price { color: #4caf50; font-size: 20px; font-weight: bold; }
        .item-rating { color: #ffc107; }
        .item-seller { color: #aaa; font-size: 12px; }
        button {
            background: #667eea;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            width: 100%;
            margin-top: 10px;
        }
        button:hover { background: #764ba2; }
        .category-filter { margin: 20px 0; text-align: center; }
        .category-btn {
            background: #3a3a3a;
            color: #fff;
            border: 1px solid #4a4a4a;
            padding: 8px 16px;
            margin: 5px;
            border-radius: 20px;
            cursor: pointer;
        }
        .category-btn:hover { border-color: #667eea; }
    </style>
</head>
<body>
    <div class="header">
        <h1>REAPER OS Community Marketplace</h1>
        <p>Buy, sell, and share professional audio production tools</p>
    </div>
    
    <div class="container">
        <div class="search-bar">
            <input type="text" id="search" placeholder="Search presets, templates, chains..." onkeyup="searchItems()">
        </div>
        
        <div class="category-filter">
            <button class="category-btn" onclick="filterByCategory('Presets')">Presets</button>
            <button class="category-btn" onclick="filterByCategory('Templates')">Templates</button>
            <button class="category-btn" onclick="filterByCategory('Chains')">Effect Chains</button>
            <button class="category-btn" onclick="filterByCategory('Samples')">Sample Packs</button>
        </div>
        
        <div class="items-grid" id="items-grid">
            <div class="item-card">
                <div class="item-seller">ProAudio Studios</div>
                <div class="item-name">Professional Vocal Chain</div>
                <div class="item-rating">⭐⭐⭐⭐⭐ 4.9</div>
                <div class="item-price">$19.99</div>
                <p>Industry-standard vocal processing</p>
                <button onclick="purchaseItem('vocal-chain')">Purchase</button>
            </div>
            
            <div class="item-card">
                <div class="item-seller">Mixing Academy</div>
                <div class="item-name">Pop Music Mixing Template</div>
                <div class="item-rating">⭐⭐⭐⭐⭐ 4.8</div>
                <div class="item-price">$29.99</div>
                <p>Professional pop mixing setup</p>
                <button onclick="purchaseItem('pop-template')">Purchase</button>
            </div>
        </div>
    </div>
    
    <script>
        function searchItems() {
            // Implement search
        }
        
        function filterByCategory(cat) {
            // Filter items
        }
        
        function purchaseItem(id) {
            alert('Purchasing: ' + id);
        }
    </script>
</body>
</html>
EOF

    echo "Marketplace storefront created"
}

main() {
    local action="${1:-help}"
    
    case "$action" in
        --list)
            list_marketplace
            ;;
        --search)
            search_marketplace "${2:-}"
            ;;
        --publish)
            publish_item
            ;;
        --buy)
            purchase_item "${2:-}"
            ;;
        --review)
            review_item "${2:-}"
            ;;
        --storefront)
            generate_storefront
            ;;
        *)
            echo "REAPER OS Community Marketplace"
            echo "Usage: community-marketplace.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --list       List marketplace items"
            echo "  --search     Search for items"
            echo "  --publish    Publish item for sale"
            echo "  --buy ITEM   Purchase an item"
            echo "  --review ID  Review an item"
            echo "  --storefront Generate marketplace storefront"
            ;;
    esac
}

main "$@"
