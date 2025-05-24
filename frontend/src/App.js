import React, { useState, useEffect, useRef } from 'react';
import {
  Container,
  Paper,
  TextField,
  Button,
  Typography,
  Box,
  Avatar,
  Chip,
  CircularProgress,
  Alert,
  AppBar,
  Toolbar,
  IconButton,
  Divider,
  Card,
  CardContent,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Tooltip
} from '@mui/material';
import {
  Send as SendIcon,
  Android as BotIcon,
  Person as PersonIcon,
  CloudQueue as CloudIcon,
  Speed as SpeedIcon,
  Computer as ComputerIcon,
  Settings as SettingsIcon,
  Memory as MemoryIcon,
  Cloud as CloudAltIcon
} from '@mui/icons-material';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { v4 as uuidv4 } from 'uuid';
import axios from 'axios';

// Create a modern theme
const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#f50057',
    },
    background: {
      default: '#f5f5f5',
      paper: '#ffffff',
    },
  },
  shape: {
    borderRadius: 12,
  },
});

// Get API URL from runtime config or environment variable or default
const getApiUrl = () => {
  // Runtime configuration (injected by Docker)
  if (window._env_ && window._env_.REACT_APP_API_URL) {
    return window._env_.REACT_APP_API_URL;
  }
  // Build-time environment variable
  if (process.env.REACT_APP_API_URL) {
    return process.env.REACT_APP_API_URL;
  }
  // Default for local development
  return 'http://localhost:8000';
};

const API_BASE_URL = getApiUrl();

function App() {
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState('disconnected');
  const [conversationId] = useState(uuidv4());
  const [stats, setStats] = useState(null);
  const [error, setError] = useState(null);
  const [availableModels, setAvailableModels] = useState(null);
  const [currentModel, setCurrentModel] = useState(null);
  const [modelDialogOpen, setModelDialogOpen] = useState(false);
  const [modelSwitching, setModelSwitching] = useState(false);
  const messagesEndRef = useRef(null);
  const wsRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(scrollToBottom, [messages]);

  useEffect(() => {
    // Initialize WebSocket connection
    initializeWebSocket();
    
    // Fetch initial data
    fetchStats();
    fetchAvailableModels();
    fetchCurrentModel();
    
    // Cleanup on unmount
    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, []);

  const initializeWebSocket = () => {
    try {
      // Get WebSocket URL from runtime config or build from current location
      let wsUrl;
      if (window._env_ && window._env_.REACT_APP_WS_URL) {
        wsUrl = `${window._env_.REACT_APP_WS_URL}/${conversationId}`;
      } else {
        // Build WebSocket URL based on current page URL
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const host = window.location.host;
        wsUrl = `${protocol}//${host}/ws/${conversationId}`;
      }
      
      console.log('Connecting to WebSocket:', wsUrl);
      wsRef.current = new WebSocket(wsUrl);

      wsRef.current.onopen = () => {
        setConnectionStatus('connected');
        setError(null);
        console.log('WebSocket connected');
      };

      wsRef.current.onmessage = (event) => {
        const data = JSON.parse(event.data);
        
        if (data.type === 'system') {
          // Handle system messages
          console.log('System message:', data.message);
        } else if (data.response) {
          // Handle chat responses
          setMessages(prev => [...prev, {
            id: uuidv4(),
            text: data.response,
            sender: 'bot',
            timestamp: data.timestamp
          }]);
        }
        
        setIsLoading(false);
      };

      wsRef.current.onclose = () => {
        setConnectionStatus('disconnected');
        console.log('WebSocket disconnected');
        
        // Attempt to reconnect after 5 seconds
        setTimeout(() => {
          if (wsRef.current?.readyState === WebSocket.CLOSED) {
            initializeWebSocket();
          }
        }, 5000);
      };

      wsRef.current.onerror = (error) => {
        setConnectionStatus('error');
        setError('WebSocket connection failed. Falling back to HTTP API.');
        console.error('WebSocket error:', error);
      };

    } catch (error) {
      console.error('Failed to initialize WebSocket:', error);
      setError('Failed to establish real-time connection. Using HTTP API.');
    }
  };

  const fetchStats = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/stats`);
      setStats(response.data);
    } catch (error) {
      console.error('Failed to fetch stats:', error);
    }
  };

  const fetchAvailableModels = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/models`);
      setAvailableModels(response.data);
    } catch (error) {
      console.error('Failed to fetch available models:', error);
    }
  };

  const fetchCurrentModel = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/models/current`);
      setCurrentModel(response.data);
    } catch (error) {
      console.error('Failed to fetch current model:', error);
    }
  };

  const switchModel = async (provider, modelName) => {
    setModelSwitching(true);
    try {
      const response = await axios.post(`${API_BASE_URL}/models/switch`, {
        provider: provider,
        model_name: modelName
      });
      
      if (response.data.success) {
        setError(null);
        await fetchCurrentModel(); // Refresh current model info
        setMessages(prev => [...prev, {
          id: uuidv4(),
          text: `🔄 Switched to ${response.data.current_model}`,
          sender: 'system',
          timestamp: new Date().toISOString()
        }]);
      } else {
        setError(`Failed to switch model: ${response.data.message}`);
      }
    } catch (error) {
      setError('Failed to switch model. Please try again.');
      console.error('Model switch error:', error);
    } finally {
      setModelSwitching(false);
      setModelDialogOpen(false);
    }
  };

  const getProviderIcon = (provider) => {
    switch (provider) {
      case 'ollama':
        return <ComputerIcon />;
      case 'huggingface':
        return <CloudAltIcon />;
      default:
        return <MemoryIcon />;
    }
  };

  const getProviderColor = (provider) => {
    switch (provider) {
      case 'ollama':
        return 'success';
      case 'huggingface':
        return 'info';
      default:
        return 'default';
    }
  };

  const sendMessage = async () => {
    if (!inputMessage.trim()) return;

    const userMessage = {
      id: uuidv4(),
      text: inputMessage,
      sender: 'user',
      timestamp: new Date().toISOString()
    };

    setMessages(prev => [...prev, userMessage]);
    setIsLoading(true);
    setError(null);

    try {
      if (wsRef.current?.readyState === WebSocket.OPEN) {
        // Send via WebSocket
        wsRef.current.send(JSON.stringify({
          message: inputMessage,
          conversation_id: conversationId
        }));
      } else {
        // Fallback to HTTP API
        const response = await axios.post(`${API_BASE_URL}/chat`, {
          message: inputMessage,
          conversation_id: conversationId
        });

        setMessages(prev => [...prev, {
          id: uuidv4(),
          text: response.data.response,
          sender: 'bot',
          timestamp: response.data.timestamp
        }]);
        setIsLoading(false);
      }
    } catch (error) {
      setError('Failed to send message. Please try again.');
      setIsLoading(false);
      console.error('Error sending message:', error);
    }

    setInputMessage('');
  };

  const handleKeyPress = (event) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      sendMessage();
    }
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ flexGrow: 1, height: '100vh', display: 'flex', flexDirection: 'column' }}>
        <AppBar position="static" elevation={1}>
          <Toolbar>
            <BotIcon sx={{ mr: 2 }} />
            <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
              Multi-Model LLM Chatbot - Kubernetes Demo
            </Typography>
            <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
              {currentModel && (
                <Tooltip title={`${currentModel.provider}: ${currentModel.model_info?.display_name || currentModel.model_name}`}>
                  <Chip
                    icon={getProviderIcon(currentModel.provider)}
                    label={`${currentModel.model_info?.display_name || currentModel.model_name}`}
                    color={getProviderColor(currentModel.provider)}
                    size="small"
                    variant="outlined"
                    sx={{ color: 'white', borderColor: 'rgba(255,255,255,0.5)' }}
                  />
                </Tooltip>
              )}
              <IconButton 
                color="inherit" 
                onClick={() => setModelDialogOpen(true)}
                disabled={modelSwitching}
                size="small"
              >
                <SettingsIcon />
              </IconButton>
              <Chip
                icon={<CloudIcon />}
                label={connectionStatus === 'connected' ? 'Connected' : 'Disconnected'}
                color={connectionStatus === 'connected' ? 'success' : 'error'}
                size="small"
              />
              {stats && (
                <Chip
                  icon={<SpeedIcon />}
                  label={`${stats.llm_service?.messages_processed || 0} msgs`}
                  color="info"
                  size="small"
                />
              )}
            </Box>
          </Toolbar>
        </AppBar>

        <Container maxWidth="md" sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column', py: 2 }}>
          {error && (
            <Alert severity="warning" sx={{ mb: 2 }} onClose={() => setError(null)}>
              {error}
            </Alert>
          )}

          {stats && (
            <Card sx={{ mb: 2 }}>
              <CardContent sx={{ py: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="body2" color="text.secondary">
                    Pod: {stats.system?.pod_name || 'local'} | 
                    Active Connections: {stats.connections?.active_websocket_connections || 0} |
                    Uptime: {Math.round(stats.llm_service?.uptime_seconds || 0)}s
                  </Typography>
                  <IconButton size="small" onClick={fetchStats}>
                    <ComputerIcon fontSize="small" />
                  </IconButton>
                </Box>
              </CardContent>
            </Card>
          )}

          <Paper 
            elevation={3} 
            sx={{ 
              flexGrow: 1, 
              display: 'flex', 
              flexDirection: 'column',
              overflow: 'hidden'
            }}
          >
            <Box sx={{ p: 2, bgcolor: 'primary.main', color: 'white' }}>
              <Typography variant="h6">
                Chat with AI Assistant
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.9 }}>
                This chatbot is running on Kubernetes with auto-scaling capabilities
              </Typography>
            </Box>

            <Box 
              sx={{ 
                flexGrow: 1, 
                overflow: 'auto', 
                p: 2,
                display: 'flex',
                flexDirection: 'column',
                gap: 2
              }}
            >
              {messages.length === 0 && (
                <Box sx={{ textAlign: 'center', py: 4, color: 'text.secondary' }}>
                  <BotIcon sx={{ fontSize: 48, mb: 2, opacity: 0.5 }} />
                  <Typography variant="h6">
                    Welcome to the Scalable LLM Chatbot
                  </Typography>
                  <Typography variant="body2">
                    Start a conversation to test the Kubernetes deployment
                  </Typography>
                </Box>
              )}

              {messages.map((message) => (
                <Box
                  key={message.id}
                  sx={{
                    display: 'flex',
                    justifyContent: message.sender === 'user' ? 'flex-end' : message.sender === 'system' ? 'center' : 'flex-start',
                    alignItems: 'flex-start',
                    gap: 1
                  }}
                >
                  {message.sender === 'bot' && (
                    <Avatar sx={{ bgcolor: 'primary.main', width: 32, height: 32 }}>
                      <BotIcon fontSize="small" />
                    </Avatar>
                  )}
                  
                  <Paper
                    sx={{
                      p: 2,
                      maxWidth: message.sender === 'system' ? '90%' : '70%',
                      bgcolor: message.sender === 'user' ? 'primary.main' : 
                               message.sender === 'system' ? 'info.light' : 'grey.100',
                      color: message.sender === 'user' || message.sender === 'system' ? 'white' : 'text.primary',
                      textAlign: message.sender === 'system' ? 'center' : 'left',
                    }}
                  >
                    <Typography variant="body1">
                      {message.text}
                    </Typography>
                    <Typography 
                      variant="caption" 
                      sx={{ 
                        opacity: 0.7,
                        display: 'block',
                        mt: 1
                      }}
                    >
                      {new Date(message.timestamp).toLocaleTimeString()}
                    </Typography>
                  </Paper>

                  {message.sender === 'user' && (
                    <Avatar sx={{ bgcolor: 'secondary.main', width: 32, height: 32 }}>
                      <PersonIcon fontSize="small" />
                    </Avatar>
                  )}
                </Box>
              ))}

              {isLoading && (
                <Box sx={{ display: 'flex', justifyContent: 'flex-start', alignItems: 'center', gap: 1 }}>
                  <Avatar sx={{ bgcolor: 'primary.main', width: 32, height: 32 }}>
                    <BotIcon fontSize="small" />
                  </Avatar>
                  <Paper sx={{ p: 2, bgcolor: 'grey.100' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <CircularProgress size={16} />
                      <Typography variant="body2" color="text.secondary">
                        AI is thinking...
                      </Typography>
                    </Box>
                  </Paper>
                </Box>
              )}

              <div ref={messagesEndRef} />
            </Box>

            <Divider />
            
            <Box sx={{ p: 2 }}>
              <Box sx={{ display: 'flex', gap: 1 }}>
                <TextField
                  fullWidth
                  multiline
                  maxRows={3}
                  value={inputMessage}
                  onChange={(e) => setInputMessage(e.target.value)}
                  onKeyPress={handleKeyPress}
                  placeholder="Type your message..."
                  variant="outlined"
                  size="small"
                  disabled={isLoading}
                />
                <Button
                  variant="contained"
                  onClick={sendMessage}
                  disabled={!inputMessage.trim() || isLoading}
                  sx={{ minWidth: 64 }}
                >
                  <SendIcon />
                </Button>
              </Box>
            </Box>
          </Paper>
        </Container>

        {/* Model Selection Dialog */}
        <Dialog 
          open={modelDialogOpen} 
          onClose={() => setModelDialogOpen(false)}
          maxWidth="md"
          fullWidth
        >
          <DialogTitle>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <SettingsIcon />
              Select AI Model
            </Box>
          </DialogTitle>
          <DialogContent>
            {availableModels && (
              <Box sx={{ mt: 1 }}>
                <Alert severity="info" sx={{ mb: 3 }}>
                  Choose from free AI models. Local models (Ollama) run on your machine for privacy, 
                  while Hugging Face models use free cloud API.
                </Alert>
                
                <Typography variant="h6" gutterBottom>
                  🖥️ Local Models (Ollama) - Privacy Focused
                </Typography>
                <List dense>
                  {availableModels.available_models.ollama.map((model) => (
                    <ListItem 
                      key={model.name}
                      button
                      onClick={() => switchModel('ollama', model.name)}
                      disabled={modelSwitching || (currentModel?.provider === 'ollama' && currentModel?.model_name === model.name)}
                      sx={{ 
                        border: 1, 
                        borderColor: 'divider', 
                        borderRadius: 1, 
                        mb: 1,
                        bgcolor: (currentModel?.provider === 'ollama' && currentModel?.model_name === model.name) ? 'action.selected' : 'inherit'
                      }}
                    >
                      <ListItemIcon>
                        <ComputerIcon color="success" />
                      </ListItemIcon>
                      <ListItemText
                        primary={model.display_name}
                        secondary={`Size: ${model.size} | Runs locally on your machine`}
                      />
                      {(currentModel?.provider === 'ollama' && currentModel?.model_name === model.name) && (
                        <Chip label="Current" color="success" size="small" />
                      )}
                    </ListItem>
                  ))}
                </List>

                <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>
                  ☁️ Cloud Models (Hugging Face) - Free API
                </Typography>
                <List dense>
                  {availableModels.available_models.huggingface.map((model) => (
                    <ListItem 
                      key={model.name}
                      button
                      onClick={() => switchModel('huggingface', model.name)}
                      disabled={modelSwitching || (currentModel?.provider === 'huggingface' && currentModel?.model_name === model.name)}
                      sx={{ 
                        border: 1, 
                        borderColor: 'divider', 
                        borderRadius: 1, 
                        mb: 1,
                        bgcolor: (currentModel?.provider === 'huggingface' && currentModel?.model_name === model.name) ? 'action.selected' : 'inherit'
                      }}
                    >
                      <ListItemIcon>
                        <CloudAltIcon color="info" />
                      </ListItemIcon>
                      <ListItemText
                        primary={model.display_name}
                        secondary={`Size: ${model.size} | Free Hugging Face API`}
                      />
                      {(currentModel?.provider === 'huggingface' && currentModel?.model_name === model.name) && (
                        <Chip label="Current" color="info" size="small" />
                      )}
                    </ListItem>
                  ))}
                </List>

                {modelSwitching && (
                  <Box sx={{ display: 'flex', justifyContent: 'center', mt: 2 }}>
                    <CircularProgress size={24} />
                    <Typography variant="body2" sx={{ ml: 1 }}>
                      Switching model...
                    </Typography>
                  </Box>
                )}
              </Box>
            )}
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setModelDialogOpen(false)} disabled={modelSwitching}>
              Close
            </Button>
          </DialogActions>
        </Dialog>
      </Box>
    </ThemeProvider>
  );
}

export default App; 