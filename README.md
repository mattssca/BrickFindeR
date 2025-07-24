# 🧱 BrickFindeR

A powerful Shiny web application for tracking LEGO set building progress. Never lose track of which pieces you've found again!

![BrickFindeR Logo](www/logo.png)

## ✨ Features

- 🔍 **Smart Set Lookup**: Enter any LEGO set number to instantly load all pieces
- 📊 **Progress Tracking**: Visual progress bar and detailed statistics
- ✅ **Intuitive Controls**: 
  - Checkboxes for single pieces
  - Plus/minus buttons for multiple pieces
- 🎨 **Modern UI**: Clean, responsive design with red accent theme
- 📱 **Mobile Friendly**: Works perfectly on phones and tablets
- 🔧 **Advanced Filtering**: Filter by color and show only missing pieces
- 🖼️ **Visual Pieces**: High-quality images for each LEGO piece
- 📝 **Set Information**: Detailed set descriptions and building instructions links

## 🚀 Quick Start

### Prerequisites

```r
# Install required R packages
install.packages(c(
  "shiny",
  "httr", 
  "jsonlite",
  "DT",
  "shinyWidgets",
  "bslib"
))
```

### Running the App

1. **Clone the repository**:
   ```bash
   git clone https://github.com/mattsada/BrickFindeR.git
   cd BrickFindeR
   ```

2. **Run the Shiny app**:
   ```r
   # In R or RStudio
   shiny::runApp()
   ```

3. **Open your browser** and navigate to the provided local URL (usually `http://127.0.0.1:XXXX`)

## 🎯 How to Use

### Basic Usage

1. **Enter a LEGO set number** (e.g., `75192-1` for the Millennium Falcon)
2. **Click "Find Pieces"** to load the set
3. **Track your progress**:
   - ✅ **Single pieces**: Use checkboxes to mark as found
   - ➕➖ **Multiple pieces**: Use +/- buttons to adjust counts
4. **Monitor progress** with the visual progress bar and statistics

### Advanced Features

- **🎨 Color Filtering**: Use the dropdown to filter pieces by specific colors
- **👁️ Missing Only**: Toggle to show only pieces you haven't found yet
- **📋 Set Information**: Click the building instructions link for official guides
- **📊 Progress Stats**: View detailed completion statistics

## 🛠️ Technical Details

### Architecture

- **Frontend**: Shiny with Bootstrap styling and custom CSS
- **Backend**: R with httr for API calls
- **Data Source**: [Rebrickable API](https://rebrickable.com/api/) for LEGO set data
- **Styling**: Custom Darth Vader-inspired theme with red accents

### File Structure

```
BrickFindeR/
├── app.R                 # Main Shiny application
├── www/
│   └── logo.png         # App logo
├── predefined_sets.csv  # Popular LEGO sets (optional)
├── README.md           # This file
└── rsconnect/          # Deployment configurations
```

### API Configuration

The app uses the Rebrickable API. You can:

1. **Use default key** (included, but rate-limited)
2. **Get your own key** at [rebrickable.com/api/](https://rebrickable.com/api/)
3. **Set environment variable**:
   ```bash
   export REBRICKABLE_API_KEY="your_api_key_here"
   ```

## 🎨 Customization

### Themes

The app features a custom red accent theme inspired by Darth Vader. Key colors:
- **Primary Red**: `#dc3545`
- **Secondary Grey**: `#6c757d` 
- **Background**: Clean white with light grey accents

### Logo

Replace `www/logo.png` with your own logo. Recommended size: 300x120px for best results.

### Popular Sets

Edit `predefined_sets.csv` to customize the dropdown of popular LEGO sets.

## 📱 Screenshots

### Desktop View
![Desktop Screenshot](screenshots/desktop.png)

### Mobile View
![Mobile Screenshot](screenshots/mobile.png)

*Screenshots coming soon!*

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[Rebrickable](https://rebrickable.com/)** for providing the comprehensive LEGO database API
- **[LEGO Group](https://www.lego.com/)** for creating the amazing building blocks that inspire this tool
- **[Shiny](https://shiny.rstudio.com/)** team for the incredible web framework
- **R Community** for the amazing ecosystem of packages

## 📞 Support

- 🐛 **Bug Reports**: [Open an issue](https://github.com/mattsada/BrickFindeR/issues)
- 💡 **Feature Requests**: [Open an issue](https://github.com/mattsada/BrickFindeR/issues)
- 📧 **Contact**: [GitHub Profile](https://github.com/mattsada)

## 🎯 Roadmap

- [ ] User accounts and saved progress
- [ ] Multiple set comparison
- [ ] Export progress reports
- [ ] Dark theme option
- [ ] Piece substitution suggestions
- [ ] Mobile app version

---

**Developed with ❤️ by [mattsada](https://github.com/mattsada)**

*Happy Building! 🧱*
