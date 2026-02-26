# Authentication Backend API Documentation

This document describes the backend API endpoints required for authentication in the Ganitha Mithura app.

## Base URL
Configure in `.env` file:
```
BACKEND_URL=http://your-backend-url:port
```

## MongoDB Setup
Your MongoDB connection string is already configured:
```
MONGODB_URL=mongodb+srv://shehancynos:1234@unitrag.svzpsnc.mongodb.net/
```

---

## API Endpoints

### 1. Sign Up (Register)

**Endpoint:** `POST /api/auth/signup`

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Success Response (200/201):**
```json
{
  "success": true,
  "message": "Account created successfully",
  "user": {
    "_id": "user_mongodb_id",
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": "2026-02-25T10:30:00Z"
  },
  "token": "jwt_token_here"
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Email already exists"
}
```

---

### 2. Sign In (Login)

**Endpoint:** `POST /api/auth/signin`

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "_id": "user_mongodb_id",
    "name": "John Doe",
    "email": "john@example.com",
    "lastLogin": "2026-02-25T10:30:00Z"
  },
  "token": "jwt_token_here"
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

---

### 3. Forgot Password

**Endpoint:** `POST /api/auth/forgot-password`

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Password reset email sent successfully"
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Email not found"
}
```

---

## MongoDB User Schema

```javascript
const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: true,
    // Store hashed password using bcrypt
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  lastLogin: {
    type: Date
  }
});
```

---

## Backend Implementation Example (Node.js + Express + MongoDB)

### Install Dependencies
```bash
npm install express mongoose bcryptjs jsonwebtoken dotenv cors
```

### Basic Server Setup (server.js)

```javascript
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URL + 'ganithamithura', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('MongoDB Connected'))
.catch(err => console.error('MongoDB Error:', err));

// User Schema
const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  lastLogin: { type: Date }
});

const User = mongoose.model('User', userSchema);

// Auth Routes
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Sign Up
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    
    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Email already exists'
      });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Create user
    const user = new User({
      name,
      email,
      password: hashedPassword
    });
    
    await user.save();
    
    // Generate token
    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '30d' }
    );
    
    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt
      },
      token
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Sign In
app.post('/api/auth/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }
    
    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }
    
    // Update last login
    user.lastLogin = new Date();
    await user.save();
    
    // Generate token
    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '30d' }
    );
    
    res.json({
      success: true,
      message: 'Login successful',
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        lastLogin: user.lastLogin
      },
      token
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Forgot Password
app.post('/api/auth/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Email not found'
      });
    }
    
    // TODO: Implement email sending logic
    // For now, just return success
    
    res.json({
      success: true,
      message: 'Password reset email sent successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Environment Variables (.env)

```env
MONGODB_URL=mongodb+srv://shehancynos:1234@unitrag.svzpsnc.mongodb.net/
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
PORT=8000
```

---

## Testing the API

### Using curl:

**Sign Up:**
```bash
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}'
```

**Sign In:**
```bash
curl -X POST http://localhost:8000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Using Postman/Thunder Client:
1. Import the endpoints
2. Set the request method to POST
3. Add the JSON body
4. Send the request

---

## Security Considerations

1. **Password Hashing:** Use bcrypt with at least 10 salt rounds
2. **JWT Secret:** Use a strong, random secret key (at least 32 characters)
3. **HTTPS:** Use HTTPS in production
4. **Input Validation:** Validate and sanitize all inputs
5. **Rate Limiting:** Implement rate limiting for authentication endpoints
6. **CORS:** Configure CORS properly for your Flutter app

---

## Deployment Options

1. **Heroku:** Easy deployment for beginners
2. **Railway:** Modern platform with MongoDB support
3. **DigitalOcean:** App Platform for scalable deployments
4. **AWS/Google Cloud:** For production-grade applications

---

## Next Steps

1. **Set up the backend server** using the example code above
2. **Update the `.env` file** with your actual backend URL
3. **Test the authentication** using the Flutter app
4. **Add proper error handling** and validation
5. **Implement password reset email** functionality
6. **Add user profile** features as needed
