import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart';

void main() {
  print('Starting 10,000 items Excel dataset generation via package:excel...');

  final random = Random(42);

  final catalogs = [
    {
      'category': 'Groceries & Staples',
      'brands': ['Fortune', 'Aashirvaad', 'India Gate', 'Daawat', 'Tata Sampann', 'Dhara', 'Saffola', 'Gemini', 'Nature Fresh', 'Patanjali', 'Catch', 'MDH', 'Everest', 'Badshah', 'Organic Tattva', '24 Mantra', 'MTR', 'Kohinoor', 'Pillsbury', 'Keya', 'Urban Platter', 'Nutrela', 'Hudson Canola', 'Sundrop', 'Anveshan', 'Borges', 'Figaro', 'Leonardo', 'Del Monte', 'Barilla', 'San Remo', 'Bambino'],
      'items': ['Basmati Rice', 'Sona Masoori Rice', 'Kolam Rice', 'Brown Rice', 'Jasmine Rice', 'Wheat Flour (Atta)', 'Maida', 'Besan (Gram Flour)', 'Sooji (Rava)', 'Toor Dal', 'Moong Dal', 'Chana Dal', 'Urad Dal', 'Masoor Dal', 'Kabuli Chana', 'Kala Chana', 'Rajma', 'Refined Sunflower Oil', 'Mustard Oil', 'Rice Bran Oil', 'Groundnut Oil', 'Extra Virgin Olive Oil', 'Pure Desi Ghee', 'Cow Ghee', 'Iodized Salt', 'Rock Salt (Sendha)', 'Granulated Sugar', 'Jaggery Powder', 'Turmeric Powder', 'Red Chilli Powder', 'Coriander Powder', 'Garam Masala', 'Cumin Seeds (Jeera)', 'Mustard Seeds', 'Black Pepper Whole', 'Cardamom Green', 'Cinnamon Sticks', 'Cloves', 'Fenugreek Seeds', 'Fennel Seeds', 'Penne Rigate Pasta', 'Fusilli Pasta', 'Spaghetti', 'Macaroni', 'Vermicelli', 'Soya Chunks', 'Quinoa Grain', 'Chia Seeds', 'Flax Seeds'],
      'variants': ['Classic', 'Premium', 'Organic', 'Select', 'Super', 'Gold', 'Royal', 'Extra Fine', 'Traditional', 'Unpolished', 'Cold Pressed', 'Fortified', 'Stone Ground', 'Pure', 'Export Quality', 'Single Origin'],
      'sizes': ['100g', '200g', '250g', '400g', '500g', '1kg', '2kg', '5kg', '10kg', '1 Litre', '2 Litre', '5 Litre Tin'],
      'units': ['kg', 'packet', 'pouch', 'bottle', 'tin', 'jar'],
      'min_cost': 30.0, 'max_cost': 850.0,
      'min_margin': 1.12, 'max_margin': 1.35
    },
    {
      'category': 'Dairy & Refrigerated',
      'brands': ['Amul', 'Mother Dairy', 'Britannia', 'Nestle', 'Govind', 'Gowardhan', 'Chitale', 'Nandini', 'Epigamia', 'Milky Mist', 'President', 'Philadelphia', "D'lecta", 'Akshayakalpa', 'Country Delight', 'Heritage', "Kwality Wall's", 'Baskin Robbins', 'Haagen Dazs', 'London Dairy', 'Vadilal', 'Havmor', 'Creambell'],
      'items': ['Toned Milk', 'Full Cream Milk', 'Cow Milk', 'Buffalo Milk', 'Skimmed Milk', 'Butter Salted', 'Butter Unsalted', 'Clarified Butter Ghee', 'Processed Cheese Blocks', 'Cheese Slices', 'Mozzarella Shredded Cheese', 'Cheddar Cheese Block', 'Paneer Fresh', 'Tofu Natural', 'Greek Yogurt', 'Flavored Yogurt', 'Plain Dahi', 'Probiotic Curd', 'Whipped Cream', 'Cooking Fresh Cream', 'Condensed Milk', 'Mawa / Khoya', 'Buttermilk Spiced', 'Sweet Lassi', 'Vanilla Ice Cream', 'Belgian Chocolate Ice Cream', 'Butterscotch Ice Cream', 'Mango Duet Ice Cream', 'Almond Crunch Ice Cream', 'Frozen Green Peas', 'Frozen Sweet Corn', 'Frozen Mixed Veg', 'Frozen French Fries'],
      'variants': ['Fresh', 'Homogenized', 'Pasteurized', 'Low Fat', 'Zero Cholesterol', 'Sugar Free', 'Creamy Rich', 'Traditional', 'Greek Style', 'Probiotic', 'Artisanal', 'Garlic Herb', 'Smoked', 'Herb Infused'],
      'sizes': ['100g', '180g', '200g', '250g', '400g', '500g', '1kg', '200ml', '450ml', '500ml', '1L Tub', '700ml Tub'],
      'units': ['packet', 'tub', 'bottle', 'box', 'pouch', 'block'],
      'min_cost': 20.0, 'max_cost': 480.0,
      'min_margin': 1.10, 'max_margin': 1.28
    },
    {
      'category': 'Beverages',
      'brands': ['Coca Cola', 'Pepsi', 'Sprite', 'Fanta', 'Mountain Dew', '7Up', 'Thums Up', 'Limca', 'Mirinda', 'Red Bull', 'Monster Energy', 'Sting', 'Tropicana', 'Minute Maid', 'Real', 'Ocean Spray', 'Paper Boat', 'Raw Pressery', 'B-Fizz', 'Appy Fizz', 'Frooti', 'Maaza', 'Slice', 'Twinings', 'Lipton', 'Tetley', 'Tata Tea Gold', 'Red Label', 'Brooke Bond Taj Mahal', 'Society', 'Wagh Bakri', 'Nescafe', 'Bru', 'Davidoff', 'Blue Tokai', 'Sleepy Owl', 'Starbucks', 'Evian', 'Perrier', 'San Pellegrino', 'Himalayan', 'Aquafina', 'Kinley', 'Bisleri', 'Schweppes', 'Arizona', 'Gatorade', 'Tang', 'Rooh Afza', 'Horlicks', 'Bournvita', 'Complan', 'Boost', 'Milo'],
      'items': ['Carbonated Soft Drink', 'Sparkling Water', 'Mineral Water', 'Energy Drink', 'Isotonic Sports Drink', 'Orange Juice 100%', 'Apple Juice Nectar', 'Mixed Fruit Juice', 'Guava Juice', 'Mango Drink', 'Pomegranate Juice', 'Cranberry Cocktail', 'Coconut Water Natural', 'Iced Tea Lemon', 'Iced Tea Peach', 'Aam Panna Drink', 'Jaljeera Beverage', 'Green Tea Bags', 'Black Tea Loose Leaf', 'Earl Grey Tea', 'English Breakfast Tea', 'Masala Chai Blend', 'Chamomile Herbal Tea', 'Instant Coffee Classic', 'Filter Coffee Roasted', 'Cold Coffee Latte', 'Espresso Roast Coffee Beans', 'Malted Nutrition Drink', 'Fruit Drink Concentrate', 'Ginger Ale Soda', 'Tonic Water'],
      'variants': ['Classic', 'Zero Sugar', 'Diet', 'Extra Fizz', 'Bold Roast', 'Mild Roast', 'Spiced Masala', 'Cardamom Flavored', 'Mint Refresh', 'Tropical Splash', 'Gold Blend', 'Rich Aroma', 'Unsweetened', 'Pulp Loaded', 'Organic'],
      'sizes': ['200ml Tetra', '250ml Can', '300ml Can', '330ml Can', '500ml Pet', '750ml Glass', '1L Tetra', '1.25L Pet', '1.5L Pet', '2L Pet', '2.25L Pet', '50g Jar', '100g Jar', '200g Jar', '500g Tin', '1kg Refill Pouch', '25 Tea Bags', '50 Tea Bags', '100 Tea Bags'],
      'units': ['bottle', 'can', 'tetra', 'jar', 'packet', 'box'],
      'min_cost': 15.0, 'max_cost': 650.0,
      'min_margin': 1.15, 'max_margin': 1.40
    },
    {
      'category': 'Snacks & Confectionery',
      'brands': ["Lay's", 'Doritos', 'Pringles', 'Kurkure', 'Uncle Chipps', 'Bingo', 'Balaji', "Haldiram's", 'Bikaji', 'Bikanervala', 'Parle', 'Britannia', 'Sunfeast', 'Oreo', 'Monaco', 'Hide & Seek', 'Bourbon', 'Dark Fantasy', 'Good Day', 'Marie Gold', 'Cadbury Dairy Milk', 'Cadbury Silk', 'KitKat', 'Snickers', 'Ferrero Rocher', 'Nestle Munch', 'Kinder Joy', 'Amul Chocolate', 'Lindt', 'Mars', 'Twix', 'Toblerone', "M&M's", 'Skittles', 'Chupa Chups', 'Alpenliebe', 'Center Fresh', 'Mentos', 'Pulse', 'Happydent', 'ACT II', '4700BC', 'Nutty Gritties', 'Tong Garden', 'Cornitos'],
      'items': ['Potato Chips', 'Corn Tortilla Nachos', 'Crispy Rice Puffs', 'Extruded Spicy Sticks', 'Aloo Bhujia', 'Moong Dal Namkeen', 'Khatta Meetha Mix', 'Navratan Mixture', 'Salted Peanuts', 'Roasted Cashews', 'California Almonds Salted', 'Roasted Pistachios', 'Gourmet Popcorn Butter', 'Cheese Popcorn', 'Caramel Popcorn', 'Chocolate Chip Cookies', 'Cream Biscuits', 'Salted Crackers', 'Digestive High Fibre Biscuits', 'Butter Cookies', 'Wafer Rolls Chocolate', 'Milk Chocolate Bar', 'Dark Chocolate 70%', 'Fruit & Nut Chocolate', 'Hazelnut Chocolate Pralines', 'Crispy Wafer Chocolate', 'Peanut Caramel Candy Bar', 'Mint Chewing Gum', 'Tangy Fruit Candies', 'Toffee Caramel Chews', 'Gummy Jelly Candies', 'Roasted Makhana (Foxnuts)'],
      'variants': ['Classic Salted', 'Spanish Tomato Tango', 'Magic Masala', 'Cream & Onion', 'Cheese & Herbs', 'Flaming Hot', 'Peri Peri', 'Sweet Chilli', 'Sour Cream Onion', 'Mint Lime', 'Roasted Garlic', 'Tangy Lemon', 'Smoked BBQ', 'Rich Hazelnut', 'Silk Roast Almond', 'Dark Intense', 'Caramel Drizzle'],
      'sizes': ['30g', '45g', '52g', '75g', '90g', '115g', '150g', '200g', '250g', '300g', '400g Family Pack', '500g Jar', '1kg Tin'],
      'units': ['packet', 'pouch', 'can', 'box', 'bar', 'jar'],
      'min_cost': 8.0, 'max_cost': 520.0,
      'min_margin': 1.18, 'max_margin': 1.45
    },
    {
      'category': 'Bakery & Breakfast',
      'brands': ['Britannia', 'Modern', 'English Oven', 'Harvest Gold', "Nature's Basket", 'Bonn', "Kellogg's", 'Quaker', 'Saffola Oats', "Bagrry's", 'Yoga Bar', 'True Elements', 'Pintola', 'MyFitness', 'Alpino', 'Nutella', 'Kissan', "Hershey's", 'Mapro', 'Druk', "Mala's", 'Betty Crocker', 'Pillsbury'],
      'items': ['White Sandwich Bread', '100% Whole Wheat Bread', 'Multigrain Seeded Bread', 'Brown Bread', 'Garlic Toast Bread', 'Burger Buns Sesame', 'Hot Dog Rolls', 'Pav Buns Pack', 'Fruit Bun / Sweet Buns', 'Sourdough Artisanal Loaf', 'Pita Bread Pockets', 'Tortilla Wraps Multigrain', 'Corn Flakes Original', 'Chocos Crunchy Cereal', 'Muesli Fruit & Nut', 'Granola Crunchy Clusters', 'Rolled Oats Whole Grain', 'Instant Flavored Oats', 'Peanut Butter Crunchy', 'Peanut Butter Creamy', 'Hazelnut Cocoa Spread', 'Mixed Fruit Jam', 'Strawberry Gourmet Jam', 'Orange Marmalade', 'Chocolate Pancake Mix', 'Vanilla Cake Mix', 'Brownie Fudge Mix', 'Honey Pure Natural', 'Maple Pancake Syrup'],
      'variants': ['Original', 'Enriched with Vitamins', 'Multigrain', 'Sugar Conscious', 'Zero Added Sugar', 'Almond & Cranberry', 'Chocolate Loaded', 'High Protein', 'Organic Raw', 'Homestyle', 'Artisanal Fresh', 'Double Chocolate', 'Caramel Crunch'],
      'sizes': ['200g', '350g', '400g Loaf', '500g', '700g', '1kg Pouch', '1.2kg Family Pack', '250g Jar', '375g Jar', '510g Jar', '1kg Tub'],
      'units': ['packet', 'loaf', 'box', 'jar', 'tub', 'bottle'],
      'min_cost': 25.0, 'max_cost': 680.0,
      'min_margin': 1.15, 'max_margin': 1.38
    },
    {
      'category': 'Personal Care & Hygiene',
      'brands': ['Dove', 'Lux', 'Nivea', 'Lifebuoy', 'Dettol', 'Pears', 'Fiama', 'Palmolive', 'Santoor', 'Head & Shoulders', 'Pantene', "L'Oreal Paris", 'Sunsilk', 'Tresemme', 'Clinic Plus', 'Garnier', 'Colgate', 'Sensodyne', 'Close Up', 'Pepsodent', 'Oral-B', 'Dabur Red', 'Himalaya', 'Gillette', 'Old Spice', 'Axe', 'Fogg', 'Engage', 'Nivea Men', 'Wild Stone', 'Vaseline', "Pond's", 'Olay', 'BoroPlus', 'Clean & Clear', 'Neutrogena', 'Whisper', 'Stayfree', 'Sofy', 'Carefree'],
      'items': ['Beauty Moisturizing Bar Soap', 'Antibacterial Bath Soap', 'Glycerine Clear Soap', 'Refreshing Body Wash Shower Gel', 'Anti-Dandruff Shampoo', 'Hair Fall Defense Shampoo', 'Keratin Smooth Conditioner', 'Deep Nourish Hair Mask', 'Total Protection Toothpaste', 'Sensitive Teeth Relief Toothpaste', 'Whitening Gel Toothpaste', 'Herbal Ayurvedic Toothpaste', 'Soft Bristle Toothbrush Pack', 'Antiseptic Mouthwash', 'Deodorant Body Spray', 'Antiperspirant Roll-On', 'Eau De Parfum Spray', 'Hydrating Body Lotion', 'Deep Moisture Cold Cream', 'Sunscreen SPF 50 Gel', 'Oil Control Face Wash', 'Micellar Cleansing Water', 'Shaving Foam Sensitive', 'Triple Blade Razor System', 'Aftershave Balm Cool', 'Sanitary Pads Wings', 'Cotton Buds Swabs', 'Lip Balm Tinted'],
      'variants': ['Sensitive Care', 'Cool Menthol', 'Deep Cleanse', 'Herbal Essence', 'Aloe Vera & Neem', 'Charcoal Detox', 'Ocean Fresh', 'Lavender Calm', 'Cocoa Butter', 'Vitamin C Brightening', 'Hyaluronic Acid', 'Tea Tree Pure', 'Intense Moisture', 'Extra Long Overnight'],
      'sizes': ['75g', '100g', '125g Pack of 3', '150ml Can', '200ml Bottle', '250ml', '400ml Pump', '650ml Family', '100g Tube', '150g Tube', '200g Tube', '500ml Bottle', 'Pack of 4 Razors', 'Pack of 30 Pads'],
      'units': ['piece', 'bottle', 'tube', 'pack', 'can', 'jar'],
      'min_cost': 20.0, 'max_cost': 750.0,
      'min_margin': 1.18, 'max_margin': 1.45
    },
    {
      'category': 'Household & Cleaning',
      'brands': ['Surf Excel', 'Ariel', 'Tide', 'Rin', 'Henko', 'Comfort', 'Vanish', 'Pril', 'Vim', 'Exo', 'Lizol', 'Colin', 'Dettol', 'Harpic', 'Domex', 'Mr Muscle', 'Godrej aer', 'Ambi Pur', 'Odonil', 'Goodknight', 'All Out', 'Hit', 'Baygon', 'Scotch-Brite', 'Origami', 'Premier', 'Paseo', 'Selpak', 'Duracell', 'Eveready', 'Panasonic'],
      'items': ['Matic Front Load Detergent Powder', 'Matic Top Load Detergent Liquid', 'Stain Remover Gel', 'Fabric Conditioner Softener', 'Dishwash Gel Lemon', 'Dishwash Bar Anti-Smell', 'Surface Disinfectant Floor Cleaner', 'Glass & Multi-Surface Cleaner', 'Toilet Cleaner Power Plus', 'Drain Clog Remover', 'Room Air Freshener Spray', 'Bathroom Air Freshener Pocket', 'Mosquito Vaporizer Refill', 'Insect Killer Spray Flying', 'Cockroach Gel Bait', 'Kitchen Scrub Sponge Scrub Pad', 'Microfiber Cleaning Cloth', 'Heavy Duty Sponge Wipe', '2-Ply Kitchen Paper Towel', '3-Ply Toilet Tissue Roll Pack', 'Facial Tissue Box', 'Biodegradable Garbage Bags', 'Aluminium Food Wrap Foil', 'Cling Film Wrap', 'Alkaline AA Batteries', 'Alkaline AAA Batteries'],
      'variants': ['Lemon Fresh', 'Lavender Bloom', 'Pine Disinfectant', 'Floral Passion', 'Citrus Sparkle', 'Ocean Breeze', 'Neem Protection', 'Triple Action', 'Power Stain Buster', 'Extra Absorbent', 'Tough Grease Formula', 'Long Lasting'],
      'sizes': ['500g Pouch', '1kg Bag', '2kg Tub', '4kg Value Pack', '500ml Bottle', '750ml Squeeze', '1 Litre Refill', '2 Litre Bottle', '5 Litre Can', 'Pack of 3 Pads', 'Pack of 6 Rolls', 'Pack of 30 Bags', 'Pack of 4 Batteries', '18m Roll', '25m Roll'],
      'units': ['packet', 'bottle', 'can', 'box', 'roll', 'piece', 'pack'],
      'min_cost': 22.0, 'max_cost': 890.0,
      'min_margin': 1.14, 'max_margin': 1.35
    },
    {
      'category': 'Fresh Produce & Vegetables',
      'brands': ['Farm Fresh', 'Organic India', 'Fresh Produce Hub', "Nature's Best", 'Kisan Pride', 'Valley Greens', 'Zespri', "Driscoll's", 'Del Monte Fresh', 'Golden Orchards', 'Hydroponics Green', 'FreshVeg'],
      'items': ['Red Hybrid Tomato', 'Desi Country Tomato', 'Spanish Red Onion', 'White Pearl Onion', 'Baby Potatoes', 'Jyoti Potato', 'Fresh Ginger', 'Garlic Whole Pearl', 'Green Chillies Spicy', 'English Cucumber', 'Country Kheera', 'Fresh Mint Leaves (Pudina)', 'Coriander Fresh Bunch', 'Spinach Leaves (Palak)', 'Fenugreek Leaves (Methi)', 'Green Cabbage', 'White Cauliflower', 'Green Capsicum', 'Red & Yellow Bell Peppers', 'Purple Round Brinjal', 'Long Bottle Gourd (Lauki)', 'Bitter Gourd (Karela)', 'Lady Finger (Bhindi)', 'French Beans Tender', 'Green Peas Fresh Pods', 'Orange Carrot', 'Red Winter Beetroot', 'Sweet Potato', 'Broccoli Crowns', 'Zucchini Green', 'Button Mushrooms Fresh', 'Sweet Corn Cobs', 'Royal Gala Apple', 'Shimla Red Apple', 'Robusta Ripe Banana', 'Yellaki Sweet Banana', 'Nagpur Juicy Orange', 'Kinnow Fresh', 'Mosambi Sweet Lime', 'Alphonso Mango (Seasonal)', 'Kesar Mango', 'Anar Ruby Pomegranate', 'Seedless Green Grapes', 'Black Globe Grapes', 'Papaya Semi-Ripe', 'Watermelon Dark Striped', 'Muskmelon Honey Dew', 'Kashmir Walnut Kernels', 'Fresh Green Coconut Tender'],
      'variants': ['Grade A Hydroponic', 'Fresh Local Harvest', 'Organically Cultivated', 'Imported Premium', 'Washed & Graded', 'Tender Select', 'Naturally Ripened', 'Crisp Farm Direct', 'Export Variety'],
      'sizes': ['250g Pack', '500g Pack', '1kg Net Bag', '2kg Bag', '1 Piece', '1 Bunch', 'Pack of 4', 'Pack of 6', '500g Tray Wrapped'],
      'units': ['kg', 'bundle', 'piece', 'pack', 'tray'],
      'min_cost': 12.0, 'max_cost': 380.0,
      'min_margin': 1.15, 'max_margin': 1.40
    },
    {
      'category': 'Baby Care & Kids',
      'brands': ['Pampers', 'Huggies', 'MamyPoko', "Johnson's Baby", 'Himalaya Baby', 'Sebamed', 'Chicco', 'Mothercare', 'Nestle Cerelac', 'Nestle Lactogen', 'Slurrp Farm', 'Baby Dove', 'Mamaearth Baby', 'Dexolac', 'Similac'],
      'items': ['Baby Diaper Pants Soft', 'Tape Diapers Premium', 'Gentle Cleansing Baby Wipes', 'Baby Moisture Soap Bar', 'Tear-Free Baby Shampoo', 'Baby Massage Oil Pure', 'Moisturizing Baby Lotion', 'Soothing Diaper Rash Cream', 'Baby Talc-Free Powder', 'Wheat Apple Baby Cereal', 'Rice Veg Baby Cereal', 'Infant Milk Formula Stage 1', 'Follow-up Milk Formula Stage 2', 'Organic Ragi Banana Porridge', 'Kids Millet Crunchy Cookies', 'Silicone Baby Feeder Bottle', 'Soft Grip Teether Toy', 'Tear-Free Kids Body Wash'],
      'variants': ['Newborn (NB)', 'Small (S)', 'Medium (M)', 'Large (L)', 'Extra Large (XL)', 'XXL Jumbo', 'Hypoallergenic', 'Dermatologist Tested', 'Chamomile Enriched', 'Aloe Soothing', '100% Organic Grains', 'Clinically Proven Mild'],
      'sizes': ['Pack of 24', 'Pack of 42', 'Pack of 64', 'Pack of 72', '72 Wipes Lid', '80 Wipes Pack', '100ml Bottle', '200ml Bottle', '400ml Pump', '300g Tin', '400g Refill', '500g Tin'],
      'units': ['packet', 'box', 'bottle', 'tube', 'tin', 'piece'],
      'min_cost': 45.0, 'max_cost': 950.0,
      'min_margin': 1.12, 'max_margin': 1.30
    },
    {
      'category': 'Canned, Sauces & Instant Foods',
      'brands': ['Maggi', 'Knorr', "Ching's Secret", 'Top Ramen', 'Wai Wai', 'Sunfeast YiPPee', 'Kissan', 'Heinz', 'Veeba', 'Dr. Oetker Funfoods', "Hellmann's", 'Sriracha', 'Tabasco', 'Del Monte', 'American Garden', 'Pintola', 'Smith & Jones', 'MTR Ready-to-Eat', 'Tata Sampann Yumside', "Haldiram's Minute Khana", "Campbell's", 'Golden Crown', 'Urban Platter', 'Wingreens Farms'],
      'items': ['2-Minute Masala Noodles', 'Oats Noodles Healthy', 'Cupped Hot & Spicy Noodles', 'Hakka Chinese Noodles', 'Schezwan Chutney Cooking Sauce', 'Soy Sauce Dark Chinese', 'Green Chilli Hot Sauce', 'Red Chilli Dipping Sauce', 'Rich Tomato Ketchup Bottle', 'Eggless Sandwich Mayonnaise', 'Burger & Sandwich Spread', 'Cheesy Jalapeno Dip', 'Sweet Corn Veg Soup Mix', 'Tomato Herb Instant Soup', 'Ready-to-Eat Dal Makhani', 'Ready-to-Eat Paneer Butter Masala', 'Ready-to-Eat Rajma Masala', 'Ready-to-Eat Chana Masala', 'Canned Sweet Whole Kernel Corn', 'Canned Sliced Button Mushrooms', 'Canned Chickpeas in Brine', 'Canned Red Kidney Beans', 'Canned Pineapple Slices Syrup', 'Pitted Black Spanish Olives', 'Sliced Green Olives Pickled', 'Jalapeno Slices Pickled', 'Hot Salsa Dip Mexican', 'Pasta & Pizza Sauce Classic'],
      'variants': ['Extra Spicy', 'Authentic Recipe', 'No Onion No Garlic', 'Chef\'s Special', 'Olive Oil Infused', 'Italian Herb', 'Zesty Lime', 'Garlic Flavored', 'Sweet & Tangy', 'Rich Thick Sauce', 'Ready in 3 Mins'],
      'sizes': ['70g Single', '140g Double', '280g 4-Pack', '420g Family Pack', '200g Pouch', '300g Pouch', '400g Tin', '500g Jar', '850g Tin', '1kg Squeeze Bottle', '1.2kg Mega Pack'],
      'units': ['packet', 'bottle', 'can', 'jar', 'pouch', 'tin'],
      'min_cost': 12.0, 'max_cost': 480.0,
      'min_margin': 1.16, 'max_margin': 1.42
    },
    {
      'category': 'Pet Supplies & Animal Care',
      'brands': ['Pedigree', 'Whiskas', 'Royal Canin', 'Drools', 'Purina Supercoat', 'Meat Up', 'Sheba', 'Farmina N&D', 'Himalaya Animal Health', 'Goodies', 'Choostix', 'Kennel Kitchen', 'CatSan', 'Barkbuddies'],
      'items': ['Adult Dry Dog Food Chicken & Veg', 'Puppy Growth Dry Dog Food Milk & Rice', 'Adult Dry Cat Food Ocean Fish', 'Kitten Growth Wet Pouch Tuna', 'Wet Dog Food Gravy Chicken Liver', 'Dog Calcium Milk Bone Chews', 'Pressed Rawhide Bones Dog Treat', 'Crunchy Dental Cat Treats', 'Soft Chicken Jerky Strips for Dogs', 'Herbal Anti-Tick Flea Pet Shampoo', 'Pet Odor Eliminator Spray', 'Silica Gel Cat Litter Clumping', 'Bentonite Lavender Cat Litter', 'Stainless Steel Pet Food Bowl Double', 'Nylon Reflective Dog Leash & Collar', 'Rubber Squeaky Fetch Ball Toy'],
      'variants': ['Real Chicken & Meat', 'Ocean Fish & Salmon', 'Grain Free High Protein', 'Veterinary Diet Formula', 'Sensitive Stomach', 'Natural Calcium Boost', 'Long Lasting Chew', 'Dust Free 99%'],
      'sizes': ['80g Pouch', '100g Pouch', '400g Pack', '1.2kg Bag', '3kg Value Bag', '10kg Mega Bag', '20kg Breeder Pack', '200ml Bottle', '500ml Bottle', '5kg Bag Litter', '10kg Bag Litter'],
      'units': ['bag', 'packet', 'pouch', 'bottle', 'piece', 'can'],
      'min_cost': 35.0, 'max_cost': 1850.0,
      'min_margin': 1.15, 'max_margin': 1.35
    },
    {
      'category': 'Organic, Health & Gourmet',
      'brands': ['Organic Tattva', '24 Mantra', 'True Elements', 'Slurrp Farm', 'Raw Pressery', 'Kapiva', 'Neuherbs', 'Prov', 'Nutty Gritties', 'Wingreens', 'Sprig', 'Borges', 'Monini', 'Barilla Collezione', 'Typhoo', 'Twinings', 'Lindt Excellence', 'Walkers', 'Loacker', 'St. Dalfour', 'Bonne Maman', 'Kombucha Culture'],
      'items': ['Cold Pressed Extra Virgin Coconut Oil', 'Raw Apple Cider Vinegar with Mother', 'Unprocessed Raw Forest Honey', 'Organic Himalayan White Honey', 'Natural Almond Butter Unsweetened', 'Gourmet Cashew Butter Roasted', 'Organic Brown Flax Seeds', 'Whole White Quinoa', 'Organic Black Chia Seeds', 'Raw Pumpkin Seeds Unsalted', 'Sunflower Seeds Roasted', 'Gluten Free Multigrain Flour', 'Ancient Emmer Khapli Wheat Flour', 'Almond Flour Superfine Blanch', 'Gluten Free Rolled Oats', 'Organic Green Tea Sencha', 'Matcha Ceremonial Japanese Tea', 'Kombucha Fermented Green Tea Drink', '100% Fruit Spread Wild Blueberry', 'Gourmet Four Seasons Peppercorns Grinder', 'Himalayan Pink Rock Salt Grinder', 'Balsamic Vinegar of Modena IGP', 'White Truffle Flavored Olive Oil', 'Artisanal Tagliatelle Egg Pasta', 'Gourmet Pure Butter Shortbread Cookies', 'Italian Hazelnut Cream Wafers Quadrate', '90% Cacao Supreme Dark Chocolate Bar'],
      'variants': ['100% Certified Organic', 'Cold Pressed Raw', 'Gluten Free Certified', 'Non-GMO Project Verified', 'Stone Ground Artisanal', 'Zero Additives Pure', 'Rich Antioxidants', 'Single Estate Handpicked', 'Artisanal Italian'],
      'sizes': ['100g Jar', '150g Jar', '200g Pack', '250g Bottle', '350g Jar', '500g Bottle', '500g Bag', '1kg Bag', '250ml Glass', '500ml Glass Bottle', '750ml Bottle'],
      'units': ['jar', 'bottle', 'packet', 'box', 'can', 'pouch'],
      'min_cost': 85.0, 'max_cost': 1650.0,
      'min_margin': 1.20, 'max_margin': 1.50
    }
  ];

  final targetCount = 10000;
  final seenNames = <String>{};
  final items = <Map<String, dynamic>>[];
  int skuCounter = 10001;
  const barcodeBase = 8901234500000;

  int catIndex = 0;
  while (items.length < targetCount) {
    final catInfo = catalogs[catIndex % catalogs.length];
    catIndex++;

    final catName = catInfo['category'] as String;
    final brands = catInfo['brands'] as List<String>;
    final productItems = catInfo['items'] as List<String>;
    final variants = catInfo['variants'] as List<String>;
    final sizes = catInfo['sizes'] as List<String>;
    final units = catInfo['units'] as List<String>;

    final brand = brands[random.nextInt(brands.length)];
    final item = productItems[random.nextInt(productItems.length)];
    final variant = variants[random.nextInt(variants.length)];
    final size = sizes[random.nextInt(sizes.length)];
    final unit = units[random.nextInt(units.length)];

    final style = random.nextInt(4);
    String fullName;
    if (style == 0) {
      fullName = '$brand $item ($variant) - $size';
    } else if (style == 1) {
      fullName = '$brand $variant $item $size';
    } else if (style == 2) {
      fullName = '$brand $item - $size [$variant]';
    } else {
      fullName = '$brand $item $size ($variant)';
    }

    if (seenNames.contains(fullName)) continue;
    seenNames.add(fullName);

    final minCost = catInfo['min_cost'] as double;
    final maxCost = catInfo['max_cost'] as double;
    final minMargin = catInfo['min_margin'] as double;
    final maxMargin = catInfo['max_margin'] as double;

    final cost = double.parse((minCost + random.nextDouble() * (maxCost - minCost)).toStringAsFixed(2));
    final margin = minMargin + random.nextDouble() * (maxMargin - minMargin);
    double sp = double.parse((cost * margin).toStringAsFixed(2));
    if (sp <= cost) sp = cost + 10.0;

    int qty;
    final r = random.nextDouble();
    if (r < 0.25) {
      qty = 3 + random.nextInt(18);
    } else if (r < 0.70) {
      qty = 21 + random.nextInt(100);
    } else if (r < 0.90) {
      qty = 121 + random.nextInt(230);
    } else {
      qty = 351 + random.nextInt(450);
    }

    final stockVal = double.parse((qty * cost).toStringAsFixed(2));
    final sellingVal = double.parse((qty * sp).toStringAsFixed(2));
    final expProfit = double.parse((sellingVal - stockVal).toStringAsFixed(2));

    final sku = 'SKU$skuCounter';
    final barcode = '${barcodeBase + skuCounter}';

    items.add({
      'sku': sku,
      'barcode': barcode,
      'name': fullName,
      'category': catName,
      'unit': unit,
      'quantity': qty,
      'cost_price': cost,
      'selling_price': sp,
      'stock_value': stockVal,
      'cost_value': stockVal,
      'selling_value': sellingVal,
      'expected_profit': expProfit,
    });

    skuCounter++;
  }

  print('Generated ${items.length} distinct products in memory. Creating Excel files...');

  // 1. Current Stock (10,000 items)
  {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headers = ['SKU/Barcode', 'Name', 'Category', 'Unit', 'Quantity', 'Cost Price', 'Selling Price', 'Stock Value'];
    for (int c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).value = headers[c];
    }

    for (int r = 0; r < items.length; r++) {
      final it = items[r];
      final rowIdx = r + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).value = it['barcode'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).value = it['name'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).value = it['category'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).value = it['unit'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx)).value = it['quantity'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx)).value = it['cost_price'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).value = it['selling_price'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx)).value = it['stock_value'];
    }

    final bytes = excel.encode()!;
    final path = 'h:/POS/super_market-main/inventory_report_current_stock_10000.xlsx';
    File(path).writeAsBytesSync(bytes);
    print('Created $path (${bytes.length} bytes)');
  }

  // 2. Stock Valuation (10,000 items)
  {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headers = ['SKU/Barcode', 'Name', 'Quantity', 'Cost Price', 'Selling Price', 'Cost Value', 'Selling Value', 'Expected Profit'];
    for (int c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).value = headers[c];
    }

    for (int r = 0; r < items.length; r++) {
      final it = items[r];
      final rowIdx = r + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).value = it['barcode'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).value = it['name'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).value = it['quantity'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).value = it['cost_price'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx)).value = it['selling_price'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx)).value = it['cost_value'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).value = it['selling_value'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx)).value = it['expected_profit'];
    }

    final bytes = excel.encode()!;
    final path = 'h:/POS/super_market-main/inventory_report_stock_valuation_10000.xlsx';
    File(path).writeAsBytesSync(bytes);
    print('Created $path (${bytes.length} bytes)');
  }

  // 3. Item Master (10,000 items)
  {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headers = ['Name', 'SKU', 'Barcode', 'Unit', 'Category', 'Cost Price', 'Selling Price', 'Tax Name', 'Tax Rate', 'Tax Type', 'Has Expiry'];
    for (int c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).value = headers[c];
    }

    for (int r = 0; r < items.length; r++) {
      final it = items[r];
      final rowIdx = r + 1;
      final hasExpiry = ['Dairy & Refrigerated', 'Beverages', 'Bakery & Breakfast', 'Fresh Produce & Vegetables', 'Baby Care & Kids'].contains(it['category']) ? 'yes' : 'no';
      final taxRate = ['Beverages', 'Personal Care & Hygiene', 'Household & Cleaning', 'Pet Supplies & Animal Care'].contains(it['category']) ? 18.0 : (['Snacks & Confectionery', 'Bakery & Breakfast', 'Canned, Sauces & Instant Foods'].contains(it['category']) ? 12.0 : 5.0);
      final taxType = r % 2 == 0 ? 'inclusive' : 'exclusive';

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).value = it['name'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).value = it['sku'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).value = it['barcode'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).value = it['unit'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx)).value = it['category'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx)).value = it['cost_price'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).value = it['selling_price'];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx)).value = 'GST';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIdx)).value = taxRate;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx)).value = taxType;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIdx)).value = hasExpiry;
    }

    final bytes = excel.encode()!;
    final path = 'h:/POS/super_market-main/sample_items_10000.xlsx';
    File(path).writeAsBytesSync(bytes);
    print('Created $path (${bytes.length} bytes)');
  }

  print('All 3 files generated successfully! Testing decoding with package:excel...');
  final testBytes = File('h:/POS/super_market-main/inventory_report_current_stock_10000.xlsx').readAsBytesSync();
  final testDecoded = Excel.decodeBytes(testBytes);
  print('Decoded Current Stock table count: ${testDecoded.tables.length}, sheet rows: ${testDecoded.tables.values.first.rows.length}');
}
