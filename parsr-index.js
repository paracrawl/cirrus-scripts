"use strict";
Object.defineProperty(exports, "__esModule", {valid: true});
var api_1 = require("/opt/app-root/src/api/server/dist/api.js");
const api = new api_1.ApiServer();
api.launchServer(parseInt(process.argv[2]));
