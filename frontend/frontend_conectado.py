"""
╔════════════════════════════════════════════════════════════════════════════════╗
║                                                                                ║
║                   FRONTEND CONECTADO - VERSIÓN ARREGLADA                       ║
║              Frontend Tkinter conectado a API Flask + Oracle                   ║
║                                                                                ║
╚════════════════════════════════════════════════════════════════════════════════╝
"""

import tkinter as tk
from tkinter import ttk, messagebox
import requests
import json
from datetime import datetime
import threading

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

API_BASE_URL = "http://127.0.0.1:5000"
API_TIMEOUT = 10

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE LOGGING
# ═══════════════════════════════════════════════════════════════════════════════

def log_idle(category, message):
    """Logging con timestamps para IDLE"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {category:12} | {message}")

# ═══════════════════════════════════════════════════════════════════════════════
# CLASE PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════════════

class FrontendConectadoApp:
    """Frontend conectado a API REST"""
    
    def __init__(self, root):
        self.root = root
        self.root.title("LEGO STORE - Sistema de Inscripciones")
        self.root.geometry("900x700")
        
        log_idle("START", "INICIANDO APLICACIÓN FRONTEND CONECTADO")
        
        # Datos
        self.tours_data = []
        self.productos_data = []
        self.tiendas_data = []
        self.inscripciones_data = []
        
        self.cliente_actual = {}
        self.participantes = []
        self.tour_seleccionado = None
        
        # Cargar datos desde API
        self.cargar_datos_api()
        
        # Crear interfaz
        self.crear_interfaz()
    
    def cargar_datos_api(self):
        """Cargar datos desde API en thread separado"""
        def _cargar():
            log_idle("LOAD", "Iniciando carga de datos...")
            
            try:
                # Verificar salud del API
                log_idle("API", "API Call: GET /health")
                response = requests.get(
                    f"{API_BASE_URL}/health",
                    timeout=API_TIMEOUT
                )
                
                if response.status_code != 200:
                    log_idle("ERROR", f"Backend retornó código: {response.status_code}")
                    messagebox.showerror(
                        "Error",
                        "❌ Backend API no disponible\n\nAsegúrate de ejecutar:\npython backend_api.py"
                    )
                    self.root.quit()
                    return
                
                log_idle("SUCCESS", "Backend API disponible")
                
                # Cargar tours
                log_idle("API", "API Call: GET /api/v1/tours")
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/tours",
                    timeout=API_TIMEOUT
                )
                if response.status_code == 200:
                    self.tours_data = response.json()
                    log_idle("SUCCESS", f"Tours cargados: {len(self.tours_data)}")
                
                # Cargar productos
                log_idle("API", "API Call: GET /api/v1/productos")
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/productos",
                    timeout=API_TIMEOUT
                )
                if response.status_code == 200:
                    self.productos_data = response.json()
                    log_idle("SUCCESS", f"Productos cargados: {len(self.productos_data)}")
                
                # Cargar tiendas
                log_idle("API", "API Call: GET /api/v1/tiendas")
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/tiendas",
                    timeout=API_TIMEOUT
                )
                if response.status_code == 200:
                    self.tiendas_data = response.json()
                    log_idle("SUCCESS", f"Tiendas cargadas: {len(self.tiendas_data)}")
                
                # Cargar inscripciones
                log_idle("API", "API Call: GET /api/v1/inscripciones")
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/inscripciones",
                    timeout=API_TIMEOUT
                )
                if response.status_code == 200:
                    self.inscripciones_data = response.json()
                    log_idle("SUCCESS", f"Inscripciones cargadas: {len(self.inscripciones_data)}")
                
                log_idle("SUCCESS", "✅ Todos los datos cargados correctamente")
            
            except requests.exceptions.ConnectionError:
                log_idle("ERROR", "❌ No se pudo conectar al Backend")
                messagebox.showerror(
                    "Error de Conexión",
                    "❌ No se puede conectar a Backend API\n\nAsegúrate de ejecutar:\npython backend_api.py"
                )
                self.root.quit()
            
            except Exception as e:
                log_idle("ERROR", f"Error cargando datos: {e}")
                messagebox.showerror("Error", f"Error cargando datos:\n{e}")
        
        # Ejecutar en thread
        thread = threading.Thread(target=_cargar, daemon=True)
        thread.start()
    
    def crear_interfaz(self):
        """Crear interfaz gráfica"""
        log_idle("UI", "Creando interfaz gráfica...")
        
        # Notebook (Pestañas)
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Pestaña 1: Tours
        self.crear_pestaña_tours()
        
        # Pestaña 2: Inscripción
        self.crear_pestaña_inscripcion()
        
        # Pestaña 3: Resumen
        self.crear_pestaña_resumen()
        
        log_idle("SUCCESS", "Interfaz gráfica creada")
    
    def crear_pestaña_tours(self):
        """Pestaña de Tours Disponibles"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="Tours Disponibles")
        
        # Título
        title = ttk.Label(frame, text="🎫 Tours Disponibles", font=("Arial", 14, "bold"))
        title.pack(pady=10)
        
        # Frame para tabla
        table_frame = ttk.Frame(frame)
        table_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Tabla
        columns = ("ID", "Tour", "Fecha", "País", "Precio")
        self.tours_tree = ttk.Treeview(table_frame, columns=columns, height=15)
        self.tours_tree.column("#0", width=0, stretch=tk.NO)
        self.tours_tree.column("ID", anchor=tk.CENTER, width=50)
        self.tours_tree.column("Tour", anchor=tk.W, width=200)
        self.tours_tree.column("Fecha", anchor=tk.CENTER, width=100)
        self.tours_tree.column("País", anchor=tk.W, width=150)
        self.tours_tree.column("Precio", anchor=tk.CENTER, width=100)
        
        self.tours_tree.heading("#0", text="")
        self.tours_tree.heading("ID", text="ID")
        self.tours_tree.heading("Tour", text="Nombre Tour")
        self.tours_tree.heading("Fecha", text="Fecha Salida")
        self.tours_tree.heading("País", text="País")
        self.tours_tree.heading("Precio", text="Precio Base")
        
        self.tours_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # Scroll
        scrollbar = ttk.Scrollbar(table_frame, orient=tk.VERTICAL, command=self.tours_tree.yview)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.tours_tree.configure(yscroll=scrollbar.set)
        
        # Llenar tabla
        self.actualizar_tabla_tours()
        
        # Botón seleccionar
        ttk.Button(frame, text="✓ Seleccionar Tour", command=self.seleccionar_tour).pack(pady=10)
    
    def actualizar_tabla_tours(self):
        """Actualizar tabla de tours"""
        # Limpiar
        for item in self.tours_tree.get_children():
            self.tours_tree.delete(item)
        
        # Llenar
        for tour in self.tours_data:
            self.tours_tree.insert(
                "",
                tk.END,
                values=(
                    tour.get("TOUR_ID", ""),
                    tour.get("TOUR_NAME", ""),
                    tour.get("FECHA_SALIDA", ""),
                    tour.get("NOMBRE_PAIS", ""),
                    f"${tour.get('PRECIO_BASE', 0):.2f}"
                )
            )
    
    def seleccionar_tour(self):
        """Seleccionar tour"""
        selection = self.tours_tree.selection()
        if not selection:
            messagebox.showwarning("Advertencia", "Por favor selecciona un tour")
            return
        
        item = self.tours_tree.item(selection[0])
        values = item["values"]
        
        self.tour_seleccionado = {
            "tour_id": values[0],
            "tour_name": values[1],
            "fecha": values[2],
            "pais": values[3],
            "precio": values[4]
        }
        
        log_idle("TOUR", f"Tour seleccionado: {self.tour_seleccionado['tour_name']}")
        messagebox.showinfo("Éxito", f"✓ Tour seleccionado:\n{self.tour_seleccionado['tour_name']}")
    
    def crear_pestaña_inscripcion(self):
        """Pestaña de Nueva Inscripción"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="Nueva Inscripción")
        
        # Canvas con scroll
        canvas = tk.Canvas(frame, highlightthickness=0)
        scrollbar = ttk.Scrollbar(frame, orient=tk.VERTICAL, command=canvas.yview)
        scrollable = ttk.Frame(canvas)
        
        scrollable.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Contenido
        # Título
        title = ttk.Label(scrollable, text="📝 Nueva Inscripción", font=("Arial", 14, "bold"))
        title.pack(pady=10)
        
        # Tour seleccionado
        tour_frame = ttk.LabelFrame(scrollable, text="Tour Seleccionado")
        tour_frame.pack(fill=tk.X, padx=10, pady=5)
        
        self.label_tour = ttk.Label(tour_frame, text="Ninguno seleccionado", foreground="red")
        self.label_tour.pack(pady=10)
        
        # Cliente
        client_frame = ttk.LabelFrame(scrollable, text="Datos del Cliente")
        client_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(client_frame, text="Nombre:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=5)
        self.entry_nombre = ttk.Entry(client_frame, width=30)
        self.entry_nombre.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(client_frame, text="Email:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=5)
        self.entry_email = ttk.Entry(client_frame, width=30)
        self.entry_email.grid(row=1, column=1, padx=5, pady=5)
        
        ttk.Label(client_frame, text="DNI:").grid(row=2, column=0, sticky=tk.W, padx=5, pady=5)
        self.entry_dni = ttk.Entry(client_frame, width=30)
        self.entry_dni.grid(row=2, column=1, padx=5, pady=5)
        
        # Botón
        button_frame = ttk.Frame(scrollable)
        button_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(button_frame, text="💾 Guardar Inscripción", command=self.guardar_inscripcion).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="🔄 Limpiar", command=self.limpiar_formulario).pack(side=tk.LEFT, padx=5)
    
    def guardar_inscripcion(self):
        """Guardar inscripción"""
        if not self.tour_seleccionado:
            messagebox.showwarning("Advertencia", "Por favor selecciona un tour primero")
            return
        
        nombre = self.entry_nombre.get().strip()
        email = self.entry_email.get().strip()
        dni = self.entry_dni.get().strip()
        
        if not all([nombre, email, dni]):
            messagebox.showwarning("Advertencia", "Por favor completa todos los campos")
            return
        
        try:
            log_idle("API", "API Call: POST /api/v1/inscripciones")
            
            payload = {
                "tour_id": self.tour_seleccionado["tour_id"],
                "cliente_nombre": nombre,
                "cliente_email": email,
                "cliente_dni": dni,
                "monto_total": 1000.0
            }
            
            response = requests.post(
                f"{API_BASE_URL}/api/v1/inscripciones",
                json=payload,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 201:
                log_idle("SUCCESS", f"Inscripción guardada: {nombre}")
                messagebox.showinfo("Éxito", f"✓ Inscripción de {nombre} guardada en BD")
                self.limpiar_formulario()
            else:
                log_idle("ERROR", f"Error guardando inscripción: {response.status_code}")
                messagebox.showerror("Error", "Error guardando inscripción")
        
        except Exception as e:
            log_idle("ERROR", f"Error: {e}")
            messagebox.showerror("Error", f"Error: {e}")
    
    def limpiar_formulario(self):
        """Limpiar formulario"""
        self.entry_nombre.delete(0, tk.END)
        self.entry_email.delete(0, tk.END)
        self.entry_dni.delete(0, tk.END)
    
    def crear_pestaña_resumen(self):
        """Pestaña de Resumen"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="Resumen")
        
        # Título
        title = ttk.Label(frame, text="📊 Resumen de Inscripciones", font=("Arial", 14, "bold"))
        title.pack(pady=10)
        
        # Frame para tabla
        table_frame = ttk.Frame(frame)
        table_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Tabla
        columns = ("ID", "Tour", "Cliente", "Email", "Fecha", "Estado")
        self.resumen_tree = ttk.Treeview(table_frame, columns=columns, height=15)
        self.resumen_tree.column("#0", width=0, stretch=tk.NO)
        self.resumen_tree.column("ID", anchor=tk.CENTER, width=50)
        self.resumen_tree.column("Tour", anchor=tk.W, width=150)
        self.resumen_tree.column("Cliente", anchor=tk.W, width=150)
        self.resumen_tree.column("Email", anchor=tk.W, width=150)
        self.resumen_tree.column("Fecha", anchor=tk.CENTER, width=100)
        self.resumen_tree.column("Estado", anchor=tk.CENTER, width=80)
        
        self.resumen_tree.heading("#0", text="")
        self.resumen_tree.heading("ID", text="ID")
        self.resumen_tree.heading("Tour", text="Tour")
        self.resumen_tree.heading("Cliente", text="Cliente")
        self.resumen_tree.heading("Email", text="Email")
        self.resumen_tree.heading("Fecha", text="Fecha")
        self.resumen_tree.heading("Estado", text="Estado")
        
        self.resumen_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # Scroll
        scrollbar = ttk.Scrollbar(table_frame, orient=tk.VERTICAL, command=self.resumen_tree.yview)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.resumen_tree.configure(yscroll=scrollbar.set)
        
        # Llenar tabla
        self.actualizar_tabla_resumen()
        
        # Botón refresh
        ttk.Button(frame, text="🔄 Actualizar", command=self.actualizar_tabla_resumen).pack(pady=10)
    
    def actualizar_tabla_resumen(self):
        """Actualizar tabla de resumen"""
        # Limpiar
        for item in self.resumen_tree.get_children():
            self.resumen_tree.delete(item)
        
        # Cargar del API
        try:
            response = requests.get(
                f"{API_BASE_URL}/api/v1/inscripciones",
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 200:
                inscripciones = response.json()
                self.inscripciones_data = inscripciones
                
                # Llenar
                for insc in inscripciones:
                    self.resumen_tree.insert(
                        "",
                        tk.END,
                        values=(
                            insc.get("INSCRIPCION_ID", ""),
                            insc.get("TOUR_ID", ""),
                            insc.get("CLIENTE_NOMBRE", ""),
                            insc.get("CLIENTE_EMAIL", ""),
                            insc.get("FECHA_INSCRIPCION", ""),
                            insc.get("ESTADO", "")
                        )
                    )
                
                log_idle("SUCCESS", f"Tabla actualizada: {len(inscripciones)} registros")
        
        except Exception as e:
            log_idle("ERROR", f"Error actualizando tabla: {e}")

# ═══════════════════════════════════════════════════════════════════════════════
# INICIAR APLICACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("=" * 80)
    log_idle("INFO", "════════════════════════════════════════════════════════════════════════════════")
    log_idle("INFO", "FRONTEND CONECTADO A API - LEGO STORE")
    log_idle("INFO", "════════════════════════════════════════════════════════════════════════════════")
    log_idle("INFO", "")
    log_idle("INFO", "📌 INSTRUCCIONES:")
    log_idle("INFO", "   1. Asegúrate de que backend_api.py está corriendo")
    log_idle("INFO", "   2. Se cargarán datos automáticamente desde la BD")
    log_idle("INFO", "   3. Los logs aparecerán en esta consola")
    log_idle("INFO", "")
    log_idle("INFO", "════════════════════════════════════════════════════════════════════════════════")
    print("=" * 80)
    
    root = tk.Tk()
    app = FrontendConectadoApp(root)
    root.mainloop()
