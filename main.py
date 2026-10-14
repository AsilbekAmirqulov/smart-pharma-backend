from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="Smart Pharma API", version="1.0.0")

# --- CORS SOZLAMASI (Brauzer xatoligini bartaraf etish uchun) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- MA'LUMOTLAR MODELI ---
class QueueBooking(BaseModel):
    pharmacy_id: int
    medicine_name: str
    pickup_time: str
    user_phone: str

# --- TEST MA'LUMOTLAR BAZASI ---
MEDICINES_DB = {
    "paracetamol": [
        {"id": 1, "name": "Grand Pharm", "address": "Chilonzor 5", "distance_km": 0.8, "price_uzs": 5000},
        {"id": 2, "name": "Best Pharm", "address": "Yunusobod 11", "distance_km": 2.4, "price_uzs": 4500},
    ],
    "kyupen": [
        {"id": 1, "name": "Grand Pharm", "address": "Chilonzor 5", "distance_km": 0.8, "price_uzs": 12000},
    ]
}

BOOKINGS_DB = []

# --- API ENDPOINTLARI ---
@app.get("/")
def home():
    return {"status": "Active", "message": "Smart Pharma Server ishlamoqda!"}

# 1. Dorilarni qidirish (Flutter kodi bilan moslashtirildi)
@app.get("/search-medicine/")
def search_medicine(name: str):
    query = name.lower().strip()
    if query in MEDICINES_DB:
        return {"medicine": query, "pharmacies": MEDICINES_DB[query]}
    return {"medicine": query, "message": "Dori topilmadi", "pharmacies": []}

# 2. Elektron navbat band qilish
@app.post("/book-queue/")
def create_queue(booking: QueueBooking):
    booking_id = f"SP-{len(BOOKINGS_DB) + 101}"
    new_entry = {
        "booking_id": booking_id,
        "pharmacy_id": booking.pharmacy_id,
        "medicine": booking.medicine_name,
        "pickup_time": booking.pickup_time,
        "user_phone": booking.user_phone,
        "status": "Ready for Pick-up",
        "qr_code_data": f"https://api.qrserver.com/v1/create-qr-code/?size=200x200&data={booking_id}"
    }
    BOOKINGS_DB.append(new_entry)
    return {"success": True, "booking_details": new_entry}