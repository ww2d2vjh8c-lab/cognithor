import { Component } from 'react'
import CognithorControlCenter from './CognithorControlCenter'

class ErrorBoundary extends Component {
  constructor(props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error }
  }

  componentDidCatch(error, errorInfo) {
    console.error('[Cognithor] Uncaught error:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          width: '100vw',
          height: '100vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          background: '#1a1a2e',
          color: '#e0e0e0',
          fontFamily: 'system-ui, -apple-system, sans-serif',
          padding: '2rem',
          textAlign: 'center',
        }}>
          <h1 style={{ fontSize: '1.5rem', marginBottom: '1rem', color: '#ff6b6b' }}>
            Something went wrong
          </h1>
          <p style={{ maxWidth: '500px', lineHeight: 1.6, marginBottom: '1.5rem', color: '#aaa' }}>
            The Control Center encountered an unexpected error.
            Reloading the page usually fixes the problem.
          </p>
          <pre style={{
            background: '#16213e',
            padding: '1rem',
            borderRadius: '8px',
            fontSize: '0.85rem',
            maxWidth: '600px',
            overflow: 'auto',
            marginBottom: '1.5rem',
            color: '#ff8a80',
            textAlign: 'left',
          }}>
            {this.state.error?.message || 'Unknown error'}
          </pre>
          <button
            onClick={() => window.location.reload()}
            style={{
              background: '#0f3460',
              color: '#e0e0e0',
              border: '1px solid #1a5276',
              borderRadius: '8px',
              padding: '0.75rem 2rem',
              fontSize: '1rem',
              cursor: 'pointer',
            }}
          >
            Reload page
          </button>
        </div>
      )
    }
    return this.props.children
  }
}

function App() {
  return (
    <div style={{ width: '100vw', height: '100vh', margin: 0, padding: 0 }}>
      <ErrorBoundary>
        <CognithorControlCenter />
      </ErrorBoundary>
    </div>
  )
}

export default App
