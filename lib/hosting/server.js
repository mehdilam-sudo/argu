const express = require('express');
const { RtcTokenBuilder, RtcRole } = require('agora-token');
require('dotenv').config();

const app = express();
const port = 8080;

// Tes identifiants Agora depuis le fichier .env
const appId = process.env.APP_ID;
const appCertificate = process.env.APP_CERTIFICATE;

// Valide les identifiants
if (!appId || !appCertificate) {
    console.error("Veuillez définir les variables d'environnement APP_ID et APP_CERTIFICATE.");
    process.exit(1);
}

// Route pour générer le jeton RTC (Real-Time Communication)
app.get('/rtc/:channelName/:uid', (req, res) => {
    const { channelName, uid } = req.params;
    const role = RtcRole.PUBLISHER;
    const expirationTimeInSeconds = 3600; // Le jeton est valide pendant 1 heure
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        channelName,
        uid === '0' ? 0 : parseInt(uid), // Gère le cas de l'ID 0 ou un autre UID
        role,
        privilegeExpiredTs
    );

    res.json({ token });
});

app.listen(port, () => {
    console.log(`Serveur de jetons démarré sur http://localhost:${port}`);
});
