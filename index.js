const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

const dataFilePath = path.join(__dirname, 'datastore.json');
let datastore = { _stores: {} };

fs.readFile(dataFilePath, 'utf8', (err, data) => {
    if (err) {
        console.log('Data file does not exist. Beginning anew.');
        saveDatastore()
    } else {
        try {
            datastore = JSON.parse(data);
        } catch (e) {
            console.error('Failed to parse datastore.json, starting fresh.');
            datastore = { _stores: {} };
            saveDatastore()
        }
    }
});

const saveDatastore = () => {
    fs.writeFile(dataFilePath, JSON.stringify(datastore, null, 2), (err) => {
        if (err) {
            console.error('Error saving datastore:', err);
            return;
        }
        console.log("Saved Datastore file.");
    });
};

app.get('/ping', (req, res) => {
    res.send('OK');
});

app.post('/createdatastore', (req, res) => {
    const { name } = req.body;

    if (!name) {
        return res.status(400).json({ error: "Missing 'name' in request body." });
    }

    if (datastore._stores[name]) {
        return res.json({ success: true, message: "Datastore already exists." });
    }

    datastore._stores[name] = { created: Date.now() };
    console.log("[/createdatastore]: Created datastore with name '" + name + "'");
    saveDatastore();
    res.json({ success: true, message: "Datastore created." });
});

app.get('/getdata', (req, res) => {
    const key = req.query.key;
    if (datastore[key]) {
        console.log("[/getdata]: Found key '" + key + "' in datastore.");
        res.json(datastore[key]);
    } else {
        console.warn("[/getdata]: Failed to find key '" + key + "' in datastore.");
        res.status(404).json({ error: 'Data not found' });
    }
});

app.post('/setdata', (req, res) => {
    const { key, value } = req.body;
    if (!key || value === undefined) {
        return res.status(400).json({ error: "Missing 'key' or 'value' in request body." });
    }
    datastore[key] = value;
    console.log("[/setdata]: Wrote key '" + key + "' to datastore.");
    saveDatastore();
    res.json({ success: true });
});

app.get('/removedata', (req, res) => {
    const key = req.query.key;
    if (datastore[key]) {
        delete datastore[key];
        console.log("[/removedata]: Removed key '" + key + "' from datastore.");
        saveDatastore();
        res.json({ success: true });
    } else {
        res.status(404).json({ error: 'Data not found' });
    }
});

app.get('/getsorteddata', (req, res) => {
    const { store, minValue, maxValue } = req.query;
    let sortedData = [];

    for (const key in datastore) {
        if (key === "_stores") continue;
        if (key.startsWith(store)) {
            const value = datastore[key];
            if (typeof value === 'number' && value >= parseFloat(minValue) && value <= parseFloat(maxValue)) {
                sortedData.push({ key, value });
            }
        }
    }

    sortedData.sort((a, b) => a.value - b.value);
    res.json(sortedData);
});

app.listen(PORT, () => {
    console.log("FakeDatastore initialized!");
    console.log("This was made by CATBLOX Softworks. This is open-source.");
    console.log("Notice anything strange? File a bug report.");
    console.log("FakeDatastore is running at http://localhost:" + PORT);
});
