"""
╔════════════════════════════════════════════════════════════════════════════════╗
║                                                                                ║
║               FRONTEND LEGO TOURS - AUTOMATIZACIÓN COMPLETA                    ║
║                                                                                ║
║    Sistema de Inscripción a Tours con Validaciones de BD y Flujo de Pago      ║
║                                                                                ║
╚════════════════════════════════════════════════════════════════════════════════╝
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import requests
import json
from datetime import datetime, timedelta
import threading

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

API_BASE_URL = "http://127.0.0.1:5000"
API_TIMEOUT = 15

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE LOGGING
# ═══════════════════════════════════════════════════════════════════════════════

def log_event(category, message):
    """Log con timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {category:12} | {message}")

# ═══════════════════════════════════════════════════════════════════════════════
# APLICACIÓN PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════════════

class FrontendLegoTours:
    """Frontend para automatización de tours LEGO"""
    
    def __init__(self, root):
        self.root = root
        self.root.title("LEGO STORE - Automatización de Tours")
        self.root.geometry("1200x900")
        
        log_event("START", "INICIANDO FRONTEND - LEGO TOURS")
        
        # Datos
        self.tours_disponibles = []
        self.inscripcion_actual = None
        self.participantes_agregados = []
        self.tour_seleccionado = None
        self.fecha_tour_seleccionada = None
        
        # Variables estado
        self.estado_pago = "PENDIENTE"
        
        # Cargar datos
        self.cargar_tours()
        
        # Crear UI
        self.crear_interfaz()
    
    def cargar_tours(self):
        """Cargar tours disponibles desde API"""
        def _cargar():
            try:
                log_event("API", "Cargando tours disponibles...")
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/tours",
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    self.tours_disponibles = response.json()
                    log_event("SUCCESS", f"Tours cargados: {len(self.tours_disponibles)}")
                else:
                    log_event("ERROR", f"Error cargando tours: {response.status_code}")
                    messagebox.showerror("Error", "No se pudieron cargar los tours")
            except Exception as e:
                log_event("ERROR", str(e))
                messagebox.showerror("Error", f"Error: {e}")
        
        thread = threading.Thread(target=_cargar, daemon=True)
        thread.start()
    
    def crear_interfaz(self):
        """Crear interfaz gráfica con flujo completo"""
        
        # Notebook
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Pestaña 1: Seleccionar Tour y Fecha
        self.crear_pestaña_tours()
        
        # Pestaña 2: Agregar Participantes
        self.crear_pestaña_participantes()
        
        # Pestaña 3: Resumen e Inscripción
        self.crear_pestaña_resumen()
        
        # Pestaña 4: Pago
        self.crear_pestaña_pago()
        
        # Pestaña 5: Confirmación
        self.crear_pestaña_confirmacion()
    
    def crear_pestaña_tours(self):
        """Pestaña 1: Seleccionar Tour y Fecha"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="1️⃣ Tours Disponibles")
        
        # Título
        ttk.Label(frame, text="🎫 Tours Disponibles", font=("Arial", 16, "bold")).pack(pady=15)
        
        # Tabla de tours
        table_frame = ttk.Frame(frame)
        table_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        columns = ("Fecha", "Cupos Totales", "Costo USD", "Cupos Disponibles")
        self.tours_tree = ttk.Treeview(table_frame, columns=columns, height=10)
        self.tours_tree.column("#0", width=0, stretch=tk.NO)
        self.tours_tree.column("Fecha", anchor=tk.CENTER, width=150)
        self.tours_tree.column("Cupos Totales", anchor=tk.CENTER, width=150)
        self.tours_tree.column("Costo USD", anchor=tk.CENTER, width=150)
        self.tours_tree.column("Cupos Disponibles", anchor=tk.CENTER, width=150)
        
        self.tours_tree.heading("#0", text="")
        self.tours_tree.heading("Fecha", text="Fecha Salida")
        self.tours_tree.heading("Cupos Totales", text="Cupos Totales")
        self.tours_tree.heading("Costo USD", text="Costo por Persona")
        self.tours_tree.heading("Cupos Disponibles", text="Cupos Disponibles")
        
        self.tours_tree.pack(fill=tk.BOTH, expand=True)
        
        # Actualizar tabla
        self.actualizar_tabla_tours()
        
        # Botón seleccionar
        ttk.Button(frame, text="✓ SELECCIONAR TOUR", 
                  command=self.seleccionar_tour).pack(pady=15)
        
        # Info tour seleccionado
        self.label_tour_info = ttk.Label(frame, text="Tour: No seleccionado", foreground="red")
        self.label_tour_info.pack(pady=10)
    
    def actualizar_tabla_tours(self):
        """Actualizar tabla con tours"""
        for item in self.tours_tree.get_children():
            self.tours_tree.delete(item)
        
        for tour in self.tours_disponibles:
            cupos_disponibles = tour.get('cupos_disponibles', tour.get('to_cupos', 0))
            self.tours_tree.insert(
                "",
                tk.END,
                values=(
                    tour.get('fecha', tour.get('to_fini', '')),
                    tour.get('cupos_totales', tour.get('to_cupos', 0)),
                    f"${tour.get('costo', tour.get('to_costo', 0)):.2f}",
                    cupos_disponibles
                )
            )
    
    def seleccionar_tour(self):
        """Seleccionar tour"""
        selection = self.tours_tree.selection()
        if not selection:
            messagebox.showwarning("Advertencia", "Selecciona un tour primero")
            return
        
        item = self.tours_tree.item(selection[0])
        values = item["values"]
        
        self.fecha_tour_seleccionada = values[0]
        self.tour_seleccionado = {
            "fecha": values[0],
            "cupos_totales": int(values[1]),
            "costo_unitario": float(values[2].replace("$", "")),
            "cupos_disponibles": int(values[3])
        }
        
        self.label_tour_info.config(
            text=f"✓ Tour: {self.tour_seleccionado['fecha']} - "
                 f"${self.tour_seleccionado['costo_unitario']:.2f}/persona - "
                 f"{self.tour_seleccionado['cupos_disponibles']} cupos disponibles",
            foreground="green"
        )
        
        log_event("TOUR", f"Seleccionado: {self.fecha_tour_seleccionada}")
        messagebox.showinfo("Éxito", f"✓ Tour seleccionado: {self.fecha_tour_seleccionada}")
    
    def crear_pestaña_participantes(self):
        """Pestaña 2: Agregar Participantes"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="2️⃣ Participantes")
        
        # Título
        ttk.Label(frame, text="👥 Agregar Participantes", font=("Arial", 16, "bold")).pack(pady=15)
        
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
        
        # Info tour
        info_frame = ttk.LabelFrame(scrollable, text="Tour Seleccionado")
        info_frame.pack(fill=tk.X, padx=10, pady=5)
        self.label_part_tour = ttk.Label(info_frame, text="No seleccionado", foreground="red")
        self.label_part_tour.pack(pady=10)
        
        # Formulario participante
        form_frame = ttk.LabelFrame(scrollable, text="Datos del Participante")
        form_frame.pack(fill=tk.X, padx=10, pady=5)
        
        # Tipo participante
        ttk.Label(form_frame, text="Tipo:").grid(row=0, column=0, sticky=tk.W, padx=10, pady=8)
        self.combo_tipo = ttk.Combobox(form_frame, values=["ADULTO", "MENOR"], state="readonly", width=20)
        self.combo_tipo.grid(row=0, column=1, padx=10, pady=8)
        
        # Nombre
        ttk.Label(form_frame, text="Nombre Completo:").grid(row=1, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_nombre = ttk.Entry(form_frame, width=40)
        self.entry_nombre.grid(row=1, column=1, padx=10, pady=8)
        
        # DNI
        ttk.Label(form_frame, text="DNI:").grid(row=2, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_dni = ttk.Entry(form_frame, width=40)
        self.entry_dni.grid(row=2, column=1, padx=10, pady=8)
        
        # Fecha Nacimiento
        ttk.Label(form_frame, text="Fecha Nacimiento (YYYY-MM-DD):").grid(row=3, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_fnac = ttk.Entry(form_frame, width=40)
        self.entry_fnac.grid(row=3, column=1, padx=10, pady=8)
        
        # País Nacionalidad
        ttk.Label(form_frame, text="País Nacionalidad:").grid(row=4, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_pais_nac = ttk.Entry(form_frame, width=40)
        self.entry_pais_nac.grid(row=4, column=1, padx=10, pady=8)
        
        # Pasaporte (si no es UE)
        ttk.Label(form_frame, text="Pasaporte (si aplica):").grid(row=5, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_pasaporte = ttk.Entry(form_frame, width=40)
        self.entry_pasaporte.grid(row=5, column=1, padx=10, pady=8)
        
        # Botones
        button_frame = ttk.Frame(form_frame)
        button_frame.grid(row=6, column=0, columnspan=2, pady=15)
        
        ttk.Button(button_frame, text="➕ AGREGAR PARTICIPANTE", 
                  command=self.agregar_participante).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="🔄 LIMPIAR", 
                  command=self.limpiar_participante).pack(side=tk.LEFT, padx=5)
        
        # Tabla participantes agregados
        table_frame = ttk.LabelFrame(scrollable, text="Participantes Agregados")
        table_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        columns = ("#", "Tipo", "Nombre", "DNI", "Fecha Nac.", "País")
        self.part_tree = ttk.Treeview(table_frame, columns=columns, height=8)
        self.part_tree.column("#0", width=0, stretch=tk.NO)
        self.part_tree.column("#", anchor=tk.CENTER, width=40)
        self.part_tree.column("Tipo", anchor=tk.CENTER, width=80)
        self.part_tree.column("Nombre", anchor=tk.W, width=150)
        self.part_tree.column("DNI", anchor=tk.CENTER, width=100)
        self.part_tree.column("Fecha Nac.", anchor=tk.CENTER, width=100)
        self.part_tree.column("País", anchor=tk.W, width=150)
        
        self.part_tree.heading("#0", text="")
        self.part_tree.heading("#", text="#")
        self.part_tree.heading("Tipo", text="Tipo")
        self.part_tree.heading("Nombre", text="Nombre")
        self.part_tree.heading("DNI", text="DNI")
        self.part_tree.heading("Fecha Nac.", text="F. Nac.")
        self.part_tree.heading("País", text="País")
        
        self.part_tree.pack(fill=tk.BOTH, expand=True)
    
    def agregar_participante(self):
        """Agregar participante"""
        if not self.tour_seleccionado:
            messagebox.showwarning("Advertencia", "Selecciona un tour primero")
            return
        
        tipo = self.combo_tipo.get()
        nombre = self.entry_nombre.get().strip()
        dni = self.entry_dni.get().strip()
        fnac = self.entry_fnac.get().strip()
        pais = self.entry_pais_nac.get().strip()
        pasaporte = self.entry_pasaporte.get().strip()
        
        if not all([tipo, nombre, dni, fnac, pais]):
            messagebox.showwarning("Error", "Completa todos los campos obligatorios")
            return
        
        # Validar cupos
        if len(self.participantes_agregados) >= self.tour_seleccionado['cupos_disponibles']:
            messagebox.showwarning("Error", "No hay cupos disponibles para más participantes")
            return
        
        participante = {
            "numero": len(self.participantes_agregados) + 1,
            "tipo": tipo,
            "nombre": nombre,
            "dni": dni,
            "fnacimiento": fnac,
            "pais_nacionalidad": pais,
            "pasaporte": pasaporte if pasaporte else None
        }
        
        self.participantes_agregados.append(participante)
        
        self.part_tree.insert(
            "",
            tk.END,
            values=(
                participante["numero"],
                participante["tipo"],
                participante["nombre"],
                participante["dni"],
                participante["fnacimiento"],
                participante["pais_nacionalidad"]
            )
        )
        
        log_event("PART", f"Participante agregado: {nombre}")
        self.limpiar_participante()
        
        # Actualizar label
        self.label_part_tour.config(
            text=f"✓ {len(self.participantes_agregados)} participante(s) agregado(s)",
            foreground="green"
        )
    
    def limpiar_participante(self):
        """Limpiar formulario"""
        self.combo_tipo.set("")
        self.entry_nombre.delete(0, tk.END)
        self.entry_dni.delete(0, tk.END)
        self.entry_fnac.delete(0, tk.END)
        self.entry_pais_nac.delete(0, tk.END)
        self.entry_pasaporte.delete(0, tk.END)
    
    def crear_pestaña_resumen(self):
        """Pestaña 3: Resumen e Inscripción"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="3️⃣ Resumen")
        
        # Título
        ttk.Label(frame, text="📋 Resumen de Inscripción", font=("Arial", 16, "bold")).pack(pady=15)
        
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
        
        # Info tour
        tour_frame = ttk.LabelFrame(scrollable, text="Tour")
        tour_frame.pack(fill=tk.X, padx=10, pady=5)
        self.label_res_tour = ttk.Label(tour_frame, text="No seleccionado")
        self.label_res_tour.pack(pady=10)
        
        # Participantes
        part_frame = ttk.LabelFrame(scrollable, text="Participantes")
        part_frame.pack(fill=tk.X, padx=10, pady=5)
        self.label_res_part = ttk.Label(part_frame, text="0 participantes")
        self.label_res_part.pack(pady=10)
        
        # Cálculo costo
        cost_frame = ttk.LabelFrame(scrollable, text="Cálculo de Costo")
        cost_frame.pack(fill=tk.X, padx=10, pady=5)
        
        self.label_costo_unitario = ttk.Label(cost_frame, text="Costo unitario: $0.00")
        self.label_costo_unitario.pack(pady=5)
        
        self.label_cantidad_participantes = ttk.Label(cost_frame, text="Participantes: 0")
        self.label_cantidad_participantes.pack(pady=5)
        
        self.label_costo_total = ttk.Label(
            cost_frame, 
            text="COSTO TOTAL: $0.00",
            font=("Arial", 14, "bold"),
            foreground="green"
        )
        self.label_costo_total.pack(pady=10)
        
        # Botones
        button_frame = ttk.Frame(scrollable)
        button_frame.pack(fill=tk.X, padx=10, pady=15)
        
        ttk.Button(button_frame, text="🔄 ACTUALIZAR RESUMEN", 
                  command=self.actualizar_resumen).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="📝 CREAR INSCRIPCIÓN", 
                  command=self.crear_inscripcion).pack(side=tk.LEFT, padx=5)
    
    def actualizar_resumen(self):
        """Actualizar resumen"""
        if self.tour_seleccionado:
            self.label_res_tour.config(
                text=f"Fecha: {self.tour_seleccionado['fecha']} | "
                     f"Costo: ${self.tour_seleccionado['costo_unitario']:.2f}",
                foreground="green"
            )
        
        cantidad = len(self.participantes_agregados)
        self.label_res_part.config(text=f"{cantidad} participante(s)")
        self.label_cantidad_participantes.config(text=f"Participantes: {cantidad}")
        
        if self.tour_seleccionado and cantidad > 0:
            self.label_costo_unitario.config(
                text=f"Costo unitario: ${self.tour_seleccionado['costo_unitario']:.2f}"
            )
            costo_total = self.tour_seleccionado['costo_unitario'] * cantidad
            self.label_costo_total.config(text=f"COSTO TOTAL: ${costo_total:,.2f}")
        else:
            self.label_costo_total.config(text="COSTO TOTAL: $0.00")
    
    def crear_inscripcion(self):
        """Crear inscripción en BD"""
        if not self.tour_seleccionado or len(self.participantes_agregados) == 0:
            messagebox.showwarning("Error", "Selecciona tour y agrega participantes")
            return
        
        try:
            # Calcular costo total
            costo_total = self.tour_seleccionado['costo_unitario'] * len(self.participantes_agregados)
            
            payload = {
                "tour_fecha": self.tour_seleccionado['fecha'],
                "cantidad_participantes": len(self.participantes_agregados),
                "costo_total": costo_total,
                "participantes": self.participantes_agregados
            }
            
            log_event("API", f"Creando inscripción para {len(self.participantes_agregados)} participantes...")
            
            response = requests.post(
                f"{API_BASE_URL}/api/v1/inscripciones/crear",
                json=payload,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 201:
                resultado = response.json()
                self.inscripcion_actual = resultado
                log_event("SUCCESS", f"Inscripción creada: {resultado.get('ins_num')}")
                messagebox.showinfo("Éxito", f"✓ Inscripción creada: #{resultado.get('ins_num')}")
                self.notebook.select(3)  # Ir a pestaña de pago
            else:
                error_msg = response.json().get('error', f"Error {response.status_code}")
                log_event("ERROR", error_msg)
                messagebox.showerror("Error", f"Error creando inscripción: {error_msg}")
        
        except Exception as e:
            log_event("ERROR", str(e))
            messagebox.showerror("Error", f"Error: {e}")
    
    def crear_pestaña_pago(self):
        """Pestaña 4: Pago"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="4️⃣ Pago")
        
        # Título
        ttk.Label(frame, text="💳 Procesar Pago", font=("Arial", 16, "bold")).pack(pady=15)
        
        # Info inscripción
        info_frame = ttk.LabelFrame(frame, text="Inscripción")
        info_frame.pack(fill=tk.X, padx=10, pady=10)
        
        self.label_insc_num = ttk.Label(info_frame, text="Inscripción: No creada")
        self.label_insc_num.pack(pady=10)
        
        self.label_insc_monto = ttk.Label(info_frame, text="Monto a pagar: $0.00", 
                                         font=("Arial", 12, "bold"), foreground="blue")
        self.label_insc_monto.pack(pady=10)
        
        # Método de pago
        pay_frame = ttk.LabelFrame(frame, text="Método de Pago")
        pay_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Label(pay_frame, text="Método:").pack(anchor=tk.W, padx=10)
        self.combo_metodo_pago = ttk.Combobox(
            pay_frame,
            values=["TARJETA CRÉDITO", "TARJETA DÉBITO", "TRANSFERENCIA BANCARIA", "PAYPAL"],
            state="readonly",
            width=40
        )
        self.combo_metodo_pago.pack(padx=10, pady=5)
        
        # Datos pago
        datos_frame = ttk.LabelFrame(frame, text="Datos de Pago")
        datos_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Label(datos_frame, text="Titular:").grid(row=0, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_titular = ttk.Entry(datos_frame, width=40)
        self.entry_titular.grid(row=0, column=1, padx=10, pady=8)
        
        ttk.Label(datos_frame, text="Número de Tarjeta/Cuenta:").grid(row=1, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_numero = ttk.Entry(datos_frame, width=40, show="*")
        self.entry_numero.grid(row=1, column=1, padx=10, pady=8)
        
        # Botones
        button_frame = ttk.Frame(frame)
        button_frame.pack(fill=tk.X, padx=10, pady=15)
        
        ttk.Button(button_frame, text="✓ CONFIRMAR PAGO", 
                  command=self.procesar_pago).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="❌ CANCELAR", 
                  command=self.cancelar_pago).pack(side=tk.LEFT, padx=5)
    
    def procesar_pago(self):
        """Procesar pago"""
        if not self.inscripcion_actual:
            messagebox.showwarning("Error", "No hay inscripción para procesar pago")
            return
        
        metodo = self.combo_metodo_pago.get()
        if not metodo:
            messagebox.showwarning("Error", "Selecciona un método de pago")
            return
        
        try:
            payload = {
                "inscripcion_num": self.inscripcion_actual.get('ins_num'),
                "metodo_pago": metodo,
                "monto": self.inscripcion_actual.get('ins_total', 0)
            }
            
            log_event("API", "Procesando pago...")
            
            response = requests.post(
                f"{API_BASE_URL}/api/v1/pagos/procesar",
                json=payload,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 200:
                self.estado_pago = "PAGO"
                resultado = response.json()
                log_event("SUCCESS", "Pago procesado correctamente")
                messagebox.showinfo("Éxito", "✓ Pago procesado correctamente")
                self.notebook.select(4)  # Ir a confirmación
            else:
                error_msg = response.json().get('error', f"Error {response.status_code}")
                log_event("ERROR", error_msg)
                messagebox.showerror("Error", f"Error procesando pago: {error_msg}")
        
        except Exception as e:
            log_event("ERROR", str(e))
            messagebox.showerror("Error", f"Error: {e}")
    
    def cancelar_pago(self):
        """Cancelar pago"""
        messagebox.showinfo("Cancelado", "Pago cancelado. Puedes intentar de nuevo.")
        self.limpiar_pago()
    
    def limpiar_pago(self):
        """Limpiar form pago"""
        self.combo_metodo_pago.set("")
        self.entry_titular.delete(0, tk.END)
        self.entry_numero.delete(0, tk.END)
    
    def crear_pestaña_confirmacion(self):
        """Pestaña 5: Confirmación Final"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="5️⃣ Confirmación")
        
        # Título
        ttk.Label(frame, text="✅ Confirmación de Inscripción", font=("Arial", 16, "bold")).pack(pady=15)
        
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
        
        # Info final
        self.label_conf = scrolledtext.ScrolledText(scrollable, width=80, height=20, wrap=tk.WORD)
        self.label_conf.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Botones
        button_frame = ttk.Frame(scrollable)
        button_frame.pack(fill=tk.X, padx=10, pady=15)
        
        ttk.Button(button_frame, text="🖨️ DESCARGAR COMPROBANTE", 
                  command=self.descargar_comprobante).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="🔄 NUEVA INSCRIPCIÓN", 
                  command=self.nueva_inscripcion).pack(side=tk.LEFT, padx=5)
    
    def descargar_comprobante(self):
        """Descargar comprobante"""
        if not self.inscripcion_actual:
            messagebox.showwarning("Error", "No hay inscripción")
            return
        
        comprobante = self.generar_comprobante()
        
        # Mostrar en la pestaña
        self.label_conf.delete(1.0, tk.END)
        self.label_conf.insert(tk.END, comprobante)
        
        messagebox.showinfo("Comprobante", "Comprobante generado\n\n" + comprobante[:300] + "...")
    
    def generar_comprobante(self):
        """Generar comprobante de inscripción"""
        if not self.inscripcion_actual:
            return "No hay datos de inscripción"
        
        comprobante = f"""
╔════════════════════════════════════════════════════════════════╗
║          COMPROBANTE DE INSCRIPCIÓN - LEGO STORE TOURS        ║
╚════════════════════════════════════════════════════════════════╝

DATOS DE INSCRIPCIÓN:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Número de Inscripción: {self.inscripcion_actual.get('ins_num', 'N/A')}
Fecha de Emisión: {self.inscripcion_actual.get('ins_femision', datetime.now().strftime('%Y-%m-%d'))}
Estado: {self.estado_pago}

TOUR CONTRATADO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Fecha de Salida: {self.tour_seleccionado['fecha'] if self.tour_seleccionado else 'N/A'}
Costo Unitario: ${self.tour_seleccionado['costo_unitario']:.2f} USD
Total Participantes: {len(self.participantes_agregados)}

PARTICIPANTES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
        
        for i, p in enumerate(self.participantes_agregados, 1):
            comprobante += f"""
{i}. {p['nombre']}
   Tipo: {p['tipo']}
   DNI: {p['dni']}
   Fecha Nacimiento: {p['fnacimiento']}
   País: {p['pais_nacionalidad']}
"""
        
        costo_total = self.tour_seleccionado['costo_unitario'] * len(self.participantes_agregados) if self.tour_seleccionado else 0
        
        comprobante += f"""
CÁLCULO DE COSTO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${self.tour_seleccionado['costo_unitario']:.2f} × {len(self.participantes_agregados)} participantes = ${costo_total:,.2f}

TOTAL A PAGAR: ${costo_total:,.2f} USD

════════════════════════════════════════════════════════════════

✓ Inscripción confirmada - Pago procesado
📅 Fecha de viaje: {self.tour_seleccionado['fecha'] if self.tour_seleccionado else 'N/A'}

Gracias por tu confianza. ¡Que disfrutes el tour!
"""
        
        return comprobante
    
    def nueva_inscripcion(self):
        """Iniciar nueva inscripción"""
        self.tour_seleccionado = None
        self.participantes_agregados = []
        self.inscripcion_actual = None
        self.estado_pago = "PENDIENTE"
        
        self.notebook.select(0)  # Volver a tours
        self.label_tour_info.config(text="Tour: No seleccionado", foreground="red")
        self.label_part_tour.config(text="No seleccionado", foreground="red")
        
        messagebox.showinfo("Nueva Inscripción", "Iniciando nueva inscripción...")

# ═══════════════════════════════════════════════════════════════════════════════
# INICIAR APLICACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("=" * 80)
    log_event("INFO", "════════════════════════════════════════════════════════════════════════════════")
    log_event("INFO", "LEGO STORE - AUTOMATIZACIÓN DE TOURS")
    log_event("INFO", "════════════════════════════════════════════════════════════════════════════════")
    log_event("INFO", "")
    log_event("INFO", "📌 FLUJO:")
    log_event("INFO", "   1. Selecciona tour y fecha (verificación de cupos)")
    log_event("INFO", "   2. Agrega participantes (adultos y menores)")
    log_event("INFO", "   3. Resumen e inscripción en BD")
    log_event("INFO", "   4. Procesar pago")
    log_event("INFO", "   5. Confirmación con comprobante")
    log_event("INFO", "")
    log_event("INFO", "════════════════════════════════════════════════════════════════════════════════")
    print("=" * 80)
    
    root = tk.Tk()
    app = FrontendLegoTours(root)
    root.mainloop()
