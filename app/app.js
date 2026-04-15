const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
	  res.send(`
	      <!DOCTYPE html>
	          <html>
		      <head>
		            <title>DevOps Mini Project</title>
			          <style>
				          body {
					            font-family: Arial, sans-serif;
						              display: flex;
							                justify-content: center;
									          align-items: center;
										            height: 100vh;
											              margin: 0;
												                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
														          color: white;
															          }
																          .container {
																	            text-align: center;
																		              padding: 40px;
																			                background: rgba(255,255,255,0.1);
																					          border-radius: 10px;
																						            backdrop-filter: blur(10px);
																							            }
																								            h1 { font-size: 3em; margin: 0; }
																									            p { font-size: 1.2em; }
																										            .tech { 
																											              margin-top: 20px;
																												                display: flex;
																														          gap: 10px;
																															            justify-content: center;
																																              flex-wrap: wrap;
																																	              }
																																		              .badge {
																																			                background: rgba(255,255,255,0.2);
																																					          padding: 8px 16px;
																																						            border-radius: 20px;
																																							              font-size: 0.9em;
																																								              }
																																									            </style>
																																										        </head>
																																											    <body>
																																											          <div class="container">
																																												          <h1>🚀 DevOps Mini Project</h1>
																																													          <p>Full-Stack DevOps Pipeline Demonstration</p>
																																														          <div class="tech">
																																															            <div class="badge">🐳 Docker</div>
																																																              <div class="badge">☸️ Kubernetes</div>
																																																	                <div class="badge">🔧 Jenkins</div>
																																																			          <div class="badge">🏗️ Terraform</div>
																																																				          </div>
																																																					          <p style="margin-top: 30px; font-size: 0.9em;">
																																																						            Container ID: ${require('os').hostname()}
																																																							            </p>
																																																								          </div>
																																																									      </body>
																																																									          </html>
																																																										    `);
});

app.get('/health', (req, res) => {
	  res.status(200).json({ status: 'healthy', timestamp: new Date() });
});

app.listen(PORT, () => {
	  console.log(`Server running on port ${PORT}`);
});
