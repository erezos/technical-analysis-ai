// Test setup file
require('dotenv').config({ path: '.env.test' });

// Mock Firebase Admin SDK for tests
jest.mock('firebase-admin', () => {
  const mockAdmin = {
    initializeApp: jest.fn(),
    credential: {
      cert: jest.fn()
    },
    firestore: jest.fn(() => ({
      collection: jest.fn(() => ({
        doc: jest.fn(() => ({
          set: jest.fn().mockResolvedValue({}),
          get: jest.fn().mockResolvedValue({
            exists: true,
            data: () => ({ test: 'data' })
          }),
          update: jest.fn().mockResolvedValue({})
        })),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: jest.fn().mockResolvedValue({
          docs: []
        })
      }))
    })),
    storage: jest.fn(() => ({
      bucket: jest.fn(() => ({
        file: jest.fn(() => ({
          save: jest.fn().mockResolvedValue({}),
          getSignedUrl: jest.fn().mockResolvedValue(['https://test-url.com'])
        }))
      }))
    })),
    messaging: jest.fn(() => ({
      send: jest.fn().mockResolvedValue('test-message-id'),
      subscribeToTopic: jest.fn().mockResolvedValue({})
    })),
    FieldValue: {
      serverTimestamp: jest.fn(() => new Date())
    }
  };

  // Add firestore property to admin object
  mockAdmin.firestore.FieldValue = {
    serverTimestamp: jest.fn(() => new Date())
  };

  return mockAdmin;
});

// Mock OpenAI
jest.mock('openai', () => {
  return jest.fn().mockImplementation(() => ({
    images: {
      generate: jest.fn().mockResolvedValue({
        data: [{
          url: 'https://test-image-url.com'
        }]
      })
    }
  }));
});

// Mock node-fetch
jest.mock('node-fetch', () => jest.fn().mockResolvedValue({
  ok: true,
  arrayBuffer: () => Promise.resolve(new ArrayBuffer(8))
}));

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.FIREBASE_PROJECT_ID = 'test-project';
process.env.FIREBASE_CLIENT_EMAIL = 'test@test-project.iam.gserviceaccount.com';
process.env.FIREBASE_PRIVATE_KEY = 'test-key';
process.env.FIREBASE_STORAGE_BUCKET = 'test-bucket.appspot.com';
process.env.OPENAI_API_KEY = 'test-openai-key';
process.env.TAAPI_KEY = 'test-taapi-key';

console.log('Test environment initialized'); 