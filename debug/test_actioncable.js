// Node.js script to test ActionCable functionality
const WebSocket = require('ws');
const fs = require('fs');
const FormData = require('form-data');
const fetch = require('node-fetch');

const SERVER_URL = 'http://localhost:3000';
const WS_URL = 'ws://localhost:3000/cable';

async function testActionCable() {
  console.log('🔍 Testing ActionCable Real-time Progress Updates');
  
  // Step 1: Upload a file and get session ID
  console.log('\n📤 Step 1: Uploading file...');
  
  const form = new FormData();
  form.append('ragdoll_document[files][]', fs.createReadStream('/tmp/test_upload.txt'));
  
  try {
    const response = await fetch(`${SERVER_URL}/documents/upload_async`, {
      method: 'POST',
      body: form
    });
    
    const result = await response.json();
    console.log('Upload response:', result);
    
    if (!result.success || !result.session_id) {
      console.error('❌ Upload failed or no session ID');
      return;
    }
    
    const sessionId = result.session_id;
    console.log('✅ Upload successful, session ID:', sessionId);
    
    // Step 2: Connect to ActionCable WebSocket
    console.log('\n📡 Step 2: Connecting to ActionCable...');
    
    const ws = new WebSocket(WS_URL);
    let messagesReceived = 0;
    let progressUpdates = [];
    
    ws.on('open', function() {
      console.log('✅ WebSocket connected');
      
      // Subscribe to FileProcessingChannel
      const subscribeMessage = {
        command: 'subscribe',
        identifier: JSON.stringify({
          channel: 'FileProcessingChannel',
          session_id: sessionId
        })
      };
      
      console.log('📩 Subscribing to channel:', subscribeMessage);
      ws.send(JSON.stringify(subscribeMessage));
    });
    
    ws.on('message', function(data) {
      messagesReceived++;
      const message = JSON.parse(data);
      console.log(`📨 Message ${messagesReceived}:`, message);
      
      if (message.type === 'confirm_subscription') {
        console.log('✅ Subscription confirmed');
      } else if (message.message) {
        console.log('📊 Progress update:', message.message);
        progressUpdates.push(message.message);
        
        // Check if this looks like a progress update
        if (message.message.filename && message.message.status) {
          console.log(`  📈 File: ${message.message.filename}`);
          console.log(`  📊 Status: ${message.message.status}`);
          console.log(`  📈 Progress: ${message.message.progress}%`);
        }
      }
    });
    
    ws.on('error', function(error) {
      console.error('❌ WebSocket error:', error);
    });
    
    ws.on('close', function() {
      console.log('📡 WebSocket closed');
      console.log(`\n📊 Summary: Received ${messagesReceived} messages`);
      console.log(`📈 Progress updates received: ${progressUpdates.length}`);
      
      if (progressUpdates.length > 0) {
        console.log('✅ Real-time progress updates are working!');
      } else {
        console.log('❌ No progress updates received');
      }
      
      process.exit(0);
    });
    
    // Wait for progress updates (timeout after 30 seconds)
    setTimeout(() => {
      console.log('\n⏰ Timeout reached, closing connection...');
      ws.close();
    }, 30000);
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the test
testActionCable();