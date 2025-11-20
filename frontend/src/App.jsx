import { useState, useEffect } from 'react'
import axios from 'axios'
import './App.css'

// In produzione, usa l'URL relativo (proxy Nginx)
// In sviluppo, usa l'URL completo del backend
const API_URL = import.meta.env.VITE_API_URL || 
  (import.meta.env.PROD ? '' : 'http://localhost:8000')

function App() {
  const [emails, setEmails] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const fetchEmails = async () => {
    try {
      setLoading(true)
      const response = await axios.get(`${API_URL}/api/emails`)
      setEmails(response.data.emails || [])
      setError(null)
    } catch (err) {
      setError('Errore nel caricamento delle email')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  const clearEmails = async () => {
    if (!confirm('Sei sicuro di voler eliminare tutte le email?')) {
      return
    }
    try {
      await axios.delete(`${API_URL}/api/emails`)
      setEmails([])
    } catch (err) {
      setError('Errore nell\'eliminazione delle email')
      console.error(err)
    }
  }

  useEffect(() => {
    fetchEmails()
    // Polling ogni 5 secondi per aggiornare i dati
    const interval = setInterval(fetchEmails, 5000)
    return () => clearInterval(interval)
  }, [])

  const getRiskColor = (rischio) => {
    switch (rischio) {
      case 'alto':
        return '#ef4444'
      case 'medio':
        return '#f59e0b'
      case 'basso':
        return '#10b981'
      default:
        return '#6b7280'
    }
  }

  const getRiskLabel = (rischio) => {
    return rischio.charAt(0).toUpperCase() + rischio.slice(1)
  }

  const stats = {
    totale: emails.length,
    alto: emails.filter(e => e.rischio === 'alto').length,
    medio: emails.filter(e => e.rischio === 'medio').length,
    basso: emails.filter(e => e.rischio === 'basso').length,
  }

  return (
    <div className="app">
      <header className="header">
        <h1>🛡️ Spam Dashboard</h1>
        <p>Monitoraggio email analizzate da Flowise</p>
      </header>

      <div className="container">
        <div className="stats-grid">
          <div className="stat-card">
            <div className="stat-value">{stats.totale}</div>
            <div className="stat-label">Totale Email</div>
          </div>
          <div className="stat-card risk-high">
            <div className="stat-value">{stats.alto}</div>
            <div className="stat-label">Rischio Alto</div>
          </div>
          <div className="stat-card risk-medium">
            <div className="stat-value">{stats.medio}</div>
            <div className="stat-label">Rischio Medio</div>
          </div>
          <div className="stat-card risk-low">
            <div className="stat-value">{stats.basso}</div>
            <div className="stat-label">Rischio Basso</div>
          </div>
        </div>

        <div className="actions-bar">
          <button onClick={fetchEmails} className="btn btn-primary">
            🔄 Aggiorna
          </button>
          <button onClick={clearEmails} className="btn btn-danger">
            🗑️ Elimina Tutto
          </button>
        </div>

        {error && (
          <div className="error-message">
            {error}
          </div>
        )}

        {loading && emails.length === 0 ? (
          <div className="loading">Caricamento...</div>
        ) : emails.length === 0 ? (
          <div className="empty-state">
            <p>📭 Nessuna email ricevuta</p>
            <p className="empty-hint">Le email analizzate da Flowise appariranno qui</p>
          </div>
        ) : (
          <div className="emails-grid">
            {emails.map((email, index) => (
              <div key={index} className="email-card">
                <div className="email-header">
                  <div className="email-sender">
                    <strong>📧 {email.mittente}</strong>
                  </div>
                  <div 
                    className="risk-badge"
                    style={{ backgroundColor: getRiskColor(email.rischio) }}
                  >
                    {getRiskLabel(email.rischio)}
                  </div>
                </div>
                <div className="email-subject">
                  <strong>Oggetto:</strong> {email.oggetto}
                </div>
                <div className="email-summary">
                  <strong>Riassunto:</strong> {email.riassunto}
                </div>
                {email.timestamp && (
                  <div className="email-timestamp">
                    Ricevuta: {new Date(email.timestamp).toLocaleString('it-IT')}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default App

