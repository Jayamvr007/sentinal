# 🛡️ Sentinel - Real-Time Market Watchdog

A **cross-platform stock monitoring application** with real-time price streaming, built to demonstrate full-stack development skills across **Python, TypeScript, and Swift**.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.11+-blue.svg)
![Next.js](https://img.shields.io/badge/Next.js-15-black.svg)
![iOS](https://img.shields.io/badge/iOS-17+-blue.svg)

## ✨ Features

- **📊 Real-Time Price Streaming** - Live market data via Finnhub WebSocket API
- **🌐 Web Dashboard** - Next.js 15 with Tailwind CSS, glassmorphism UI
- **📱 iOS App** - Native SwiftUI with MVVM architecture
- **⚡ WebSocket Architecture** - Efficient bi-directional communication
- **🔄 Cross-Platform Sync** - Same data across all devices in real-time

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      FINNHUB API                                │
│                  (Real-Time Market Data)                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │ WebSocket
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (FastAPI)                            │
│  • WebSocket price broadcasting                                 │
│  • RESTful API endpoints                                        │
│  • Real-time data aggregation                                   │
└───────────────────────────┬─────────────────────────────────────┘
                            │ WebSocket /price/stream
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌─────────────────────────┐   ┌─────────────────────────┐
│   WEB (Next.js 15)      │   │   iOS (SwiftUI)         │
│   • React 19            │   │   • MVVM Architecture   │
│   • Tailwind CSS v4     │   │   • @Observable         │
│   • Real-time hooks     │   │   • URLSession WS       │
└─────────────────────────┘   └─────────────────────────┘
```

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Python 3.11+, FastAPI, WebSockets, Pydantic |
| **Web Frontend** | Next.js 15, React 19, TypeScript, Tailwind CSS v4 |
| **iOS App** | Swift 6, SwiftUI, MVVM, URLSessionWebSocketTask |
| **Data Source** | Finnhub Real-Time WebSocket API |

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Node.js 18+
- Xcode 15+ (for iOS)
- [Finnhub API Key](https://finnhub.io/register) (free)

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/sentinel.git
cd sentinel
```

### 2. Backend Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Create .env file with your Finnhub API key
echo "FINNHUB_API_KEY=your_api_key_here" > .env

# Start the server
python -m uvicorn app.main:app --reload --port 8000
```

### 3. Web Dashboard

```bash
cd web
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

### 4. iOS App

1. Open `ios/SentinelApp/SentinelApp.xcodeproj` in Xcode
2. Select your simulator or device
3. Press `⌘R` to run

## 📸 Screenshots

| Web Dashboard | iOS App |
|---------------|---------|
| Real-time price grid with glassmorphism design | Native SwiftUI with live updates |

## 🔧 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Health check |
| `GET` | `/symbols` | List all tracked symbols |
| `WS` | `/price/stream` | WebSocket for real-time prices |

## 📁 Project Structure

```
sentinel/
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── main.py          # Application entry point
│   │   ├── config.py        # Settings & configuration
│   │   ├── models/          # Pydantic schemas
│   │   ├── services/        # Business logic
│   │   └── websocket/       # WebSocket manager
│   └── requirements.txt
├── web/                     # Next.js frontend
│   ├── src/app/
│   │   ├── components/      # React components
│   │   ├── hooks/           # Custom hooks (usePriceStream)
│   │   └── types/           # TypeScript types
│   └── package.json
└── ios/                     # iOS app
    └── SentinelApp/
        ├── Models/          # Data models
        ├── Services/        # WebSocket manager
        ├── ViewModels/      # MVVM view models
        └── Views/           # SwiftUI views
```

## 🎯 Roadmap

- [x] Phase 1: Vertical Slice (Real-time streaming)
- [ ] Phase 2: Alert System (Price alerts with push notifications)
- [ ] Phase 3: User Authentication (JWT + OAuth)
- [ ] Phase 4: iOS Live Activities (Lock Screen ticker)
- [ ] Phase 5: Portfolio Tracking (Database + Charts)

## 🧪 Development

### Running Tests

```bash
# Backend
cd backend && pytest

# Web
cd web && npm test
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `FINNHUB_API_KEY` | Your Finnhub API key |
| `DEBUG` | Enable debug mode (default: true) |

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Jayam Verma**

- GitHub: [@jayamverma](https://github.com/jayamverma)
- LinkedIn: [Jayam Verma](https://linkedin.com/in/jayamverma)

---

<p align="center">
  Built with ❤️ using FastAPI, Next.js, and SwiftUI
</p>
