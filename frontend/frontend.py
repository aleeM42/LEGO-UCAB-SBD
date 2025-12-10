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
import re

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

API_BASE_URL = "http://127.0.0.1:5000"
API_TIMEOUT = 15

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE VALIDACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

def validar_solo_letras(texto, campo_nombre):
    """
    Valida que un texto contenga solo letras (incluyendo acentos y espacios).
    Retorna (es_valido, mensaje_error)
    """
    if not texto or texto.strip() == "":
        return True, None  # Los campos opcionales pueden estar vacíos
    
    # Permitir letras (incluyendo acentos), espacios, guiones y apóstrofes
    # Patrón: solo letras, espacios, guiones y apóstrofes
    patron = re.compile(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s\-\']+$')
    
    if not patron.match(texto.strip()):
        return False, f"El campo '{campo_nombre}' solo puede contener letras, espacios, guiones y apóstrofes. No se permiten números ni caracteres especiales."
    
    return True, None

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
        self.participantes_agregados = []  # Lista de dicts con {tipo, id, datos}
        self.tour_seleccionado = None
        self.fecha_tour_seleccionada = None
        self.cliente_responsable_id = None
        self.paises = []  # Lista de países para formularios
        
        # Variables estado
        self.estado_pago = "PENDIENTE"
        
        # Cargar datos
        self.cargar_tours()
        self.cargar_paises()
        
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
    
    def cargar_paises(self):
        """Cargar lista de países desde API"""
        def _cargar():
            try:
                log_event("API", "Cargando países...")
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/paises",
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    self.paises = response.json()
                    log_event("SUCCESS", f"Países cargados: {len(self.paises)}")
                else:
                    log_event("ERROR", f"Error cargando países: {response.status_code}")
            except Exception as e:
                log_event("ERROR", str(e))
        
        thread = threading.Thread(target=_cargar, daemon=True)
        thread.start()
    
    def crear_interfaz(self):
        """Crear interfaz gráfica con flujo completo"""
        
        # Notebook
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Pestaña 1: Seleccionar Tour y Fecha
        self.crear_pestaña_tours()
        
        # Pestaña 2: Registrar Cliente/Fan LEGO
        self.crear_pestaña_registro()
        
        # Pestaña 3: Agregar Participantes
        self.crear_pestaña_participantes()
        
        # Pestaña 4: Resumen e Inscripción
        self.crear_pestaña_resumen()
        
        # Pestaña 5: Pago
        self.crear_pestaña_pago()
        
        # Pestaña 6: Confirmación
        self.crear_pestaña_confirmacion()
        
        # Pestaña 7: Ventas Tienda Física
        self.crear_pestaña_ventas_fisicas()
        
        # Pestaña 8: Ventas Online
        self.crear_pestaña_ventas_online()
    
    def crear_pestaña_tours(self):
        """Pestaña 1: Seleccionar Tour y Fecha"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="1️ Tours Disponibles")
        
        # Título
        ttk.Label(frame, text="🎫 Tours Disponibles", font=("Arial", 16, "bold")).pack(pady=15)
        
        # Tabla de tours
        table_frame = ttk.Frame(frame)
        table_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        columns = ("Fecha", "Cupos Totales", "Costo USD", "Cupos Disponibles", "Estado", "Tipo")
        self.tours_tree = ttk.Treeview(table_frame, columns=columns, height=10)
        self.tours_tree.column("#0", width=0, stretch=tk.NO)
        self.tours_tree.column("Fecha", anchor=tk.CENTER, width=120)
        self.tours_tree.column("Cupos Totales", anchor=tk.CENTER, width=100)
        self.tours_tree.column("Costo USD", anchor=tk.CENTER, width=120)
        self.tours_tree.column("Cupos Disponibles", anchor=tk.CENTER, width=120)
        self.tours_tree.column("Estado", anchor=tk.CENTER, width=100)
        self.tours_tree.column("Tipo", anchor=tk.CENTER, width=80)
        
        self.tours_tree.heading("#0", text="")
        self.tours_tree.heading("Fecha", text="Fecha Salida")
        self.tours_tree.heading("Cupos Totales", text="Cupos Totales")
        self.tours_tree.heading("Costo USD", text="Costo por Persona")
        self.tours_tree.heading("Cupos Disponibles", text="Cupos Disponibles")
        self.tours_tree.heading("Estado", text="Estado")
        self.tours_tree.heading("Tipo", text="Tipo")
        
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
            fecha = tour.get('fecha', '')
            cupos_totales = tour.get('cupos_totales', 0)
            costo = tour.get('costo', 0)
            cupos_disponibles = tour.get('cupos_disponibles', 0)
            estado = tour.get('estado_inscripcion', 'CERRADA')
            
            # Color según disponibilidad y tipo
            tipo_fecha = tour.get('tipo_fecha', 'FUTURO')
            tag = "disponible" if cupos_disponibles > 0 and estado == "ABIERTA" and tipo_fecha == "FUTURO" else "cerrado"
            if tipo_fecha == "PASADO":
                tag = "pasado"
            
            self.tours_tree.insert(
                "",
                tk.END,
                values=(
                    fecha,
                    cupos_totales,
                    f"{costo:.2f} DKK",  # Precio en coronas danesas
                    cupos_disponibles,
                    estado,
                    tipo_fecha
                ),
                tags=(tag,)
            )
        
        # Configurar colores
        self.tours_tree.tag_configure("disponible", foreground="green")
        self.tours_tree.tag_configure("cerrado", foreground="orange")
        self.tours_tree.tag_configure("pasado", foreground="gray")
    
    def seleccionar_tour(self):
        """Seleccionar tour y verificar cupos disponibles"""
        selection = self.tours_tree.selection()
        if not selection:
            messagebox.showwarning("Advertencia", "Selecciona un tour primero")
            return
        
        item = self.tours_tree.item(selection[0])
        values = item["values"]
        
        fecha_tour = values[0]
        cupos_disponibles = int(values[3])
        estado = values[4] if len(values) > 4 else "CERRADA"
        
        # Verificar cupos disponibles usando la función de BD
        def _verificar_cupos():
            try:
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/tours/{fecha_tour}/cupos",
                    timeout=API_TIMEOUT
                )
                if response.status_code == 200:
                    data = response.json()
                    cupos_reales = data.get('cupos_disponibles', 0)
                    
                    self.root.after(0, lambda: self._confirmar_seleccion_tour(
                        fecha_tour, values, cupos_reales, estado
                    ))
                else:
                    self.root.after(0, lambda: messagebox.showerror(
                        "Error", f"Error verificando cupos: {response.json().get('error', 'Desconocido')}"
                    ))
            except Exception as e:
                self.root.after(0, lambda: messagebox.showerror("Error", f"Error: {e}"))
        
        thread = threading.Thread(target=_verificar_cupos, daemon=True)
        thread.start()
    
    def _confirmar_seleccion_tour(self, fecha_tour, values, cupos_reales, estado):
        """Confirmar selección de tour después de verificar cupos"""
        if cupos_reales <= 0:
            messagebox.showwarning("Sin cupos", f"No hay cupos disponibles para el tour del {fecha_tour}")
            return
        
        if estado != "ABIERTA":
            messagebox.showwarning("Inscripción cerrada", f"El período de inscripción para este tour está cerrado")
            return
        
        self.fecha_tour_seleccionada = fecha_tour
        # Extraer solo el número del costo (puede ser "3500.00 DKK" o "$3500.00")
        costo_str = values[2].replace("$", "").replace(",", "").replace("DKK", "").strip()
        self.tour_seleccionado = {
            "fecha": fecha_tour,
            "cupos_totales": int(values[1]),
            "costo_unitario": float(costo_str),
            "cupos_disponibles": cupos_reales
        }
        
        self.label_tour_info.config(
            text=f"✓ Tour: {self.tour_seleccionado['fecha']} - "
                 f"{self.tour_seleccionado['costo_unitario']:.2f} DKK/persona - "
                 f"{self.tour_seleccionado['cupos_disponibles']} cupos disponibles",
            foreground="green"
        )
        if hasattr(self, "label_part_tour"):
            self.label_part_tour.config(
            text=f"Tour seleccionado: {self.tour_seleccionado['fecha']} "
                 f"({self.tour_seleccionado['cupos_disponibles']} cupos)",
            foreground="green"
        )
        
        log_event("TOUR", f"Seleccionado: {self.fecha_tour_seleccionada} - {cupos_reales} cupos")
        messagebox.showinfo("Éxito", f"✓ Tour seleccionado: {self.fecha_tour_seleccionada}\nCupos disponibles: {cupos_reales}")
    
    def crear_pestaña_registro(self):
        """Pestaña 2: Registrar Cliente o Fan LEGO"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="2️ Registrar")
        
        # Título
        ttk.Label(frame, text="📝 Registrar Cliente o Fan LEGO", font=("Arial", 16, "bold")).pack(pady=15)
        
        # Notebook interno para Cliente y Fan LEGO
        notebook_registro = ttk.Notebook(frame)
        notebook_registro.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Sub-pestaña: Registrar Cliente
        self.crear_formulario_cliente(notebook_registro)
        
        # Sub-pestaña: Registrar Fan LEGO
        self.crear_formulario_fan_lego(notebook_registro)
    
    def crear_formulario_cliente(self, parent):
        """Formulario para registrar nuevo cliente"""
        frame = ttk.Frame(parent)
        parent.add(frame, text="Cliente Adulto")
        
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
        
        form_frame = ttk.LabelFrame(scrollable, text="Datos del Cliente")
        form_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Primer nombre
        ttk.Label(form_frame, text="Primer Nombre *:").grid(row=0, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_cli_pnombre = ttk.Entry(form_frame, width=40)
        self.entry_reg_cli_pnombre.grid(row=0, column=1, padx=10, pady=8)
        
        # Segundo nombre (opcional)
        ttk.Label(form_frame, text="Segundo Nombre:").grid(row=1, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_cli_snombre = ttk.Entry(form_frame, width=40)
        self.entry_reg_cli_snombre.grid(row=1, column=1, padx=10, pady=8)
        
        # Primer apellido
        ttk.Label(form_frame, text="Primer Apellido *:").grid(row=2, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_cli_papellido = ttk.Entry(form_frame, width=40)
        self.entry_reg_cli_papellido.grid(row=2, column=1, padx=10, pady=8)
        
        # Segundo apellido
        ttk.Label(form_frame, text="Segundo Apellido *:").grid(row=3, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_cli_sapellido = ttk.Entry(form_frame, width=40)
        self.entry_reg_cli_sapellido.grid(row=3, column=1, padx=10, pady=8)
        
        # DNI
        ttk.Label(form_frame, text="DNI *:").grid(row=4, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_cli_dni = ttk.Entry(form_frame, width=40)
        self.entry_reg_cli_dni.grid(row=4, column=1, padx=10, pady=8)
        
        # Fecha nacimiento
        ttk.Label(form_frame, text="Fecha Nacimiento (YYYY-MM-DD) *:").grid(row=5, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_cli_fnac = ttk.Entry(form_frame, width=40)
        self.entry_reg_cli_fnac.grid(row=5, column=1, padx=10, pady=8)
        
        # País nacionalidad
        ttk.Label(form_frame, text="País Nacionalidad *:").grid(row=6, column=0, sticky=tk.W, padx=10, pady=8)
        self.combo_reg_cli_nac = ttk.Combobox(form_frame, width=37, state="readonly")
        self.combo_reg_cli_nac.grid(row=6, column=1, padx=10, pady=8)
        
        # País residencia
        ttk.Label(form_frame, text="País Residencia *:").grid(row=7, column=0, sticky=tk.W, padx=10, pady=8)
        self.combo_reg_cli_reside = ttk.Combobox(form_frame, width=37, state="readonly")
        self.combo_reg_cli_reside.grid(row=7, column=1, padx=10, pady=8)
        
        # Pasaporte
        ttk.Label(form_frame, text="Número Pasaporte:").grid(row=8, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_cli_numpas = ttk.Entry(form_frame, width=40)
        self.entry_reg_cli_numpas.grid(row=8, column=1, padx=10, pady=8)
        
        # Fecha vencimiento pasaporte
        ttk.Label(form_frame, text="Vencimiento Pasaporte (YYYY-MM-DD):").grid(row=9, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_cli_fvenpas = ttk.Entry(form_frame, width=40)
        self.entry_reg_cli_fvenpas.grid(row=9, column=1, padx=10, pady=8)
        
        # Botones
        button_frame = ttk.Frame(form_frame)
        button_frame.grid(row=10, column=0, columnspan=2, pady=15)
        
        ttk.Button(button_frame, text="💾 REGISTRAR CLIENTE", 
                  command=self.registrar_cliente_nuevo).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="🔄 LIMPIAR", 
                  command=self.limpiar_formulario_cliente).pack(side=tk.LEFT, padx=5)
        
        # Resultado
        self.label_reg_cli_resultado = ttk.Label(form_frame, text="", foreground="green")
        self.label_reg_cli_resultado.grid(row=11, column=0, columnspan=2, pady=10)
        
        # Actualizar combos cuando se carguen los países
        def actualizar_combos():
            if self.paises:
                paises_list = [f"{p['p_id']} - {p['p_nom']}" for p in self.paises]
                self.combo_reg_cli_nac['values'] = paises_list
                self.combo_reg_cli_reside['values'] = paises_list
        
        self.root.after(1000, actualizar_combos)
    
    def crear_formulario_fan_lego(self, parent):
        """Formulario para registrar nuevo fan LEGO"""
        frame = ttk.Frame(parent)
        parent.add(frame, text="Fan LEGO Menor")
        
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
        
        form_frame = ttk.LabelFrame(scrollable, text="Datos del Fan LEGO")
        form_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Primer nombre
        ttk.Label(form_frame, text="Primer Nombre *:").grid(row=0, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_fl_pnombre = ttk.Entry(form_frame, width=40)
        self.entry_reg_fl_pnombre.grid(row=0, column=1, padx=10, pady=8)
        
        # Segundo nombre
        ttk.Label(form_frame, text="Segundo Nombre:").grid(row=1, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_fl_snombre = ttk.Entry(form_frame, width=40)
        self.entry_reg_fl_snombre.grid(row=1, column=1, padx=10, pady=8)
        
        # Primer apellido
        ttk.Label(form_frame, text="Primer Apellido *:").grid(row=2, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_fl_papellido = ttk.Entry(form_frame, width=40)
        self.entry_reg_fl_papellido.grid(row=2, column=1, padx=10, pady=8)
        
        # Segundo apellido
        ttk.Label(form_frame, text="Segundo Apellido *:").grid(row=3, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_fl_sapellido = ttk.Entry(form_frame, width=40)
        self.entry_reg_fl_sapellido.grid(row=3, column=1, padx=10, pady=8)
        
        # DNI
        ttk.Label(form_frame, text="DNI *:").grid(row=4, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_fl_dni = ttk.Entry(form_frame, width=40)
        self.entry_reg_fl_dni.grid(row=4, column=1, padx=10, pady=8)
        
        # Fecha nacimiento
        ttk.Label(form_frame, text="Fecha Nacimiento (YYYY-MM-DD) *:").grid(row=5, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_fl_fnac = ttk.Entry(form_frame, width=40)
        self.entry_reg_fl_fnac.grid(row=5, column=1, padx=10, pady=8)
        
        # País nacionalidad
        ttk.Label(form_frame, text="País Nacionalidad *:").grid(row=6, column=0, sticky=tk.W, padx=10, pady=8)
        self.combo_reg_fl_nac = ttk.Combobox(form_frame, width=37, state="readonly")
        self.combo_reg_fl_nac.grid(row=6, column=1, padx=10, pady=8)
        
        # Pasaporte
        ttk.Label(form_frame, text="Número Pasaporte:").grid(row=7, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_fl_numpas = ttk.Entry(form_frame, width=40)
        self.entry_reg_fl_numpas.grid(row=7, column=1, padx=10, pady=8)
        
        # Fecha vencimiento pasaporte
        ttk.Label(form_frame, text="Vencimiento Pasaporte (YYYY-MM-DD):").grid(row=8, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_fl_fvenpas = ttk.Entry(form_frame, width=40)
        self.entry_reg_fl_fvenpas.grid(row=8, column=1, padx=10, pady=8)
        
        # Representante (ID cliente)
        ttk.Label(form_frame, text="ID Representante (Cliente):").grid(row=9, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_reg_fl_repre = ttk.Entry(form_frame, width=40)
        self.entry_reg_fl_repre.grid(row=9, column=1, padx=10, pady=8)
        
        # Botones
        button_frame = ttk.Frame(form_frame)
        button_frame.grid(row=10, column=0, columnspan=2, pady=15)
        
        ttk.Button(button_frame, text="💾 REGISTRAR FAN LEGO", 
                  command=self.registrar_fan_lego_nuevo).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="🔄 LIMPIAR", 
                  command=self.limpiar_formulario_fan_lego).pack(side=tk.LEFT, padx=5)
        
        # Resultado
        self.label_reg_fl_resultado = ttk.Label(form_frame, text="", foreground="green")
        self.label_reg_fl_resultado.grid(row=11, column=0, columnspan=2, pady=10)
        
        # Actualizar combo cuando se carguen los países
        def actualizar_combo():
            if self.paises:
                paises_list = [f"{p['p_id']} - {p['p_nom']}" for p in self.paises]
                self.combo_reg_fl_nac['values'] = paises_list
        
        self.root.after(1000, actualizar_combo)
    
    def registrar_cliente_nuevo(self):
        """Registrar nuevo cliente"""
        try:
            # Obtener datos del formulario
            p_pnombre = self.entry_reg_cli_pnombre.get().strip()
            p_snombre = self.entry_reg_cli_snombre.get().strip() or None
            p_papellido = self.entry_reg_cli_papellido.get().strip()
            p_sapellido = self.entry_reg_cli_sapellido.get().strip()
            p_dni = self.entry_reg_cli_dni.get().strip()
            p_fnacimiento = self.entry_reg_cli_fnac.get().strip()
            
            # Obtener IDs de países
            nac_str = self.combo_reg_cli_nac.get()
            reside_str = self.combo_reg_cli_reside.get()
            
            if not nac_str or not reside_str:
                messagebox.showwarning("Error", "Selecciona los países de nacionalidad y residencia")
                return
            
            p_nac = int(nac_str.split(" - ")[0])
            p_reside = int(reside_str.split(" - ")[0])
            
            p_numpas = self.entry_reg_cli_numpas.get().strip() or None
            p_fvenpas = self.entry_reg_cli_fvenpas.get().strip() or None
            
            # Validar campos obligatorios
            if not all([p_pnombre, p_papellido, p_sapellido, p_dni, p_fnacimiento]):
                messagebox.showwarning("Error", "Completa todos los campos obligatorios (*)")
                return
            
            # Validar que los nombres solo contengan letras
            validaciones = [
                validar_solo_letras(p_pnombre, "Primer Nombre"),
                validar_solo_letras(p_snombre, "Segundo Nombre") if p_snombre else (True, None),
                validar_solo_letras(p_papellido, "Primer Apellido"),
                validar_solo_letras(p_sapellido, "Segundo Apellido")
            ]
            
            for es_valido, mensaje in validaciones:
                if not es_valido:
                    messagebox.showerror("Error de Validación", mensaje)
                    return
            
            payload = {
                "p_pnombre": p_pnombre,
                "p_papellido": p_papellido,
                "p_sapellido": p_sapellido,
                "p_dni": int(p_dni),
                "p_fnacimiento": p_fnacimiento,
                "p_nac": p_nac,
                "p_reside": p_reside,
                "p_snombre": p_snombre,
                "p_numpas": p_numpas,
                "p_fvenpas": p_fvenpas
            }
            
            log_event("API", "Registrando nuevo cliente...")
            response = requests.post(
                f"{API_BASE_URL}/api/v1/clientes/registrar",
                json=payload,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 201:
                resultado = response.json()
                cli_id = resultado.get('cli_id')
                self.label_reg_cli_resultado.config(
                    text=f"✓ Cliente registrado exitosamente. ID: {cli_id}",
                    foreground="green"
                )
                log_event("SUCCESS", f"Cliente registrado: ID {cli_id}")
                messagebox.showinfo("Éxito", f"✓ Cliente registrado exitosamente\nID: {cli_id}\n\nPuedes usar este ID para agregarlo como participante.")
            else:
                error_msg = response.json().get('error', f"Error {response.status_code}")
                self.label_reg_cli_resultado.config(
                    text=f"✗ Error: {error_msg}",
                    foreground="red"
                )
                messagebox.showerror("Error", f"Error registrando cliente: {error_msg}")
        except ValueError as e:
            messagebox.showerror("Error", f"Error en los datos: {e}")
        except Exception as e:
            log_event("ERROR", str(e))
            messagebox.showerror("Error", f"Error: {e}")
    
    def registrar_fan_lego_nuevo(self):
        """Registrar nuevo fan LEGO"""
        try:
            # Obtener datos del formulario
            fl_pnombre = self.entry_reg_fl_pnombre.get().strip()
            fl_snombre = self.entry_reg_fl_snombre.get().strip() or None
            fl_papellido = self.entry_reg_fl_papellido.get().strip()
            fl_sapellido = self.entry_reg_fl_sapellido.get().strip()
            fl_dni = self.entry_reg_fl_dni.get().strip()
            fl_fnacimiento = self.entry_reg_fl_fnac.get().strip()
            
            # Obtener ID de país
            nac_str = self.combo_reg_fl_nac.get()
            if not nac_str:
                messagebox.showwarning("Error", "Selecciona el país de nacionalidad")
                return
            
            fl_nac = int(nac_str.split(" - ")[0])
            
            fl_numpas = self.entry_reg_fl_numpas.get().strip() or None
            fl_fvenpas = self.entry_reg_fl_fvenpas.get().strip() or None
            fl_repre_str = self.entry_reg_fl_repre.get().strip()
            fl_repre = int(fl_repre_str) if fl_repre_str else None
            
            # Validar campos obligatorios
            if not all([fl_pnombre, fl_papellido, fl_sapellido, fl_dni, fl_fnacimiento]):
                messagebox.showwarning("Error", "Completa todos los campos obligatorios (*)")
                return
            
            # Validar que los nombres solo contengan letras
            validaciones = [
                validar_solo_letras(fl_pnombre, "Primer Nombre"),
                validar_solo_letras(fl_snombre, "Segundo Nombre") if fl_snombre else (True, None),
                validar_solo_letras(fl_papellido, "Primer Apellido"),
                validar_solo_letras(fl_sapellido, "Segundo Apellido")
            ]
            
            for es_valido, mensaje in validaciones:
                if not es_valido:
                    messagebox.showerror("Error de Validación", mensaje)
                    return
            
            payload = {
                "fl_pnombre": fl_pnombre,
                "fl_papellido": fl_papellido,
                "fl_sapellido": fl_sapellido,
                "fl_dni": int(fl_dni),
                "fl_fnacimiento": fl_fnacimiento,
                "fl_nac": fl_nac,
                "fl_snombre": fl_snombre,
                "fl_numpas": fl_numpas,
                "fl_fvenpas": fl_fvenpas,
                "fl_repre": fl_repre
            }
            
            log_event("API", "Registrando nuevo fan LEGO...")
            response = requests.post(
                f"{API_BASE_URL}/api/v1/fans-lego/registrar",
                json=payload,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 201:
                resultado = response.json()
                fl_id = resultado.get('fl_id')
                self.label_reg_fl_resultado.config(
                    text=f"✓ Fan LEGO registrado exitosamente. ID: {fl_id}",
                    foreground="green"
                )
                log_event("SUCCESS", f"Fan LEGO registrado: ID {fl_id}")
                messagebox.showinfo("Éxito", f"✓ Fan LEGO registrado exitosamente\nID: {fl_id}\n\nPuedes usar este ID para agregarlo como participante.")
            else:
                error_msg = response.json().get('error', f"Error {response.status_code}")
                self.label_reg_fl_resultado.config(
                    text=f"✗ Error: {error_msg}",
                    foreground="red"
                )
                messagebox.showerror("Error", f"Error registrando fan LEGO: {error_msg}")
        except ValueError as e:
            messagebox.showerror("Error", f"Error en los datos: {e}")
        except Exception as e:
            log_event("ERROR", str(e))
            messagebox.showerror("Error", f"Error: {e}")
    
    def limpiar_formulario_cliente(self):
        """Limpiar formulario de cliente"""
        self.entry_reg_cli_pnombre.delete(0, tk.END)
        self.entry_reg_cli_snombre.delete(0, tk.END)
        self.entry_reg_cli_papellido.delete(0, tk.END)
        self.entry_reg_cli_sapellido.delete(0, tk.END)
        self.entry_reg_cli_dni.delete(0, tk.END)
        self.entry_reg_cli_fnac.delete(0, tk.END)
        self.combo_reg_cli_nac.set("")
        self.combo_reg_cli_reside.set("")
        self.entry_reg_cli_numpas.delete(0, tk.END)
        self.entry_reg_cli_fvenpas.delete(0, tk.END)
        self.label_reg_cli_resultado.config(text="")
    
    def limpiar_formulario_fan_lego(self):
        """Limpiar formulario de fan LEGO"""
        self.entry_reg_fl_pnombre.delete(0, tk.END)
        self.entry_reg_fl_snombre.delete(0, tk.END)
        self.entry_reg_fl_papellido.delete(0, tk.END)
        self.entry_reg_fl_sapellido.delete(0, tk.END)
        self.entry_reg_fl_dni.delete(0, tk.END)
        self.entry_reg_fl_fnac.delete(0, tk.END)
        self.combo_reg_fl_nac.set("")
        self.entry_reg_fl_numpas.delete(0, tk.END)
        self.entry_reg_fl_fvenpas.delete(0, tk.END)
        self.entry_reg_fl_repre.delete(0, tk.END)
        self.label_reg_fl_resultado.config(text="")
    
    def crear_pestaña_participantes(self):
        """Pestaña 2: Agregar Participantes"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="3 Participantes")
        
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
        
        # Cliente Responsable
        responsable_frame = ttk.LabelFrame(scrollable, text="Cliente Responsable")
        responsable_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(responsable_frame, text="ID Cliente Responsable:").grid(row=0, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_cli_responsable = ttk.Entry(responsable_frame, width=20)
        self.entry_cli_responsable.grid(row=0, column=1, padx=10, pady=8)
        ttk.Button(responsable_frame, text="🔍 CONSULTAR", 
                  command=self.consultar_cliente_responsable).grid(row=0, column=2, padx=5)
        
        self.label_cli_responsable = ttk.Label(responsable_frame, text="No consultado", foreground="red")
        self.label_cli_responsable.grid(row=1, column=0, columnspan=3, padx=10, pady=5)
        
        # Formulario participante
        form_frame = ttk.LabelFrame(scrollable, text="Agregar Participante por ID")
        form_frame.pack(fill=tk.X, padx=10, pady=5)
        
        # Tipo participante
        ttk.Label(form_frame, text="Tipo:").grid(row=0, column=0, sticky=tk.W, padx=10, pady=8)
        self.combo_tipo = ttk.Combobox(form_frame, values=["ADULTO", "MENOR"], state="readonly", width=20)
        self.combo_tipo.grid(row=0, column=1, padx=10, pady=8)
        self.combo_tipo.bind("<<ComboboxSelected>>", self.on_tipo_changed)
        
        # ID del participante
        ttk.Label(form_frame, text="ID Cliente o Fan LEGO:").grid(row=1, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_id_participante = ttk.Entry(form_frame, width=20)
        self.entry_id_participante.grid(row=1, column=1, padx=10, pady=8)
        ttk.Button(form_frame, text="🔍 CONSULTAR DATOS", 
                  command=self.consultar_participante).grid(row=1, column=2, padx=5)
        
        # Área de datos consultados
        datos_frame = ttk.LabelFrame(scrollable, text="Datos Consultados")
        datos_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        self.text_datos = scrolledtext.ScrolledText(datos_frame, width=80, height=10, wrap=tk.WORD)
        self.text_datos.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Botones
        button_frame = ttk.Frame(form_frame)
        button_frame.grid(row=2, column=0, columnspan=3, pady=15)
        
        ttk.Button(button_frame, text="➕ AGREGAR A INSCRIPCIÓN", 
                  command=self.agregar_participante).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="🔄 LIMPIAR", 
                  command=self.limpiar_participante).pack(side=tk.LEFT, padx=5)
        
        # Tabla participantes agregados
        table_frame = ttk.LabelFrame(scrollable, text="Participantes Agregados a la Inscripción")
        table_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        columns = ("#", "Tipo", "ID", "Nombre", "DNI", "Edad", "País")
        self.part_tree = ttk.Treeview(table_frame, columns=columns, height=8)
        self.part_tree.column("#0", width=0, stretch=tk.NO)
        self.part_tree.column("#", anchor=tk.CENTER, width=40)
        self.part_tree.column("Tipo", anchor=tk.CENTER, width=80)
        self.part_tree.column("ID", anchor=tk.CENTER, width=60)
        self.part_tree.column("Nombre", anchor=tk.W, width=200)
        self.part_tree.column("DNI", anchor=tk.CENTER, width=100)
        self.part_tree.column("Edad", anchor=tk.CENTER, width=60)
        self.part_tree.column("País", anchor=tk.W, width=150)
        
        self.part_tree.heading("#0", text="")
        self.part_tree.heading("#", text="#")
        self.part_tree.heading("Tipo", text="Tipo")
        self.part_tree.heading("ID", text="ID")
        self.part_tree.heading("Nombre", text="Nombre Completo")
        self.part_tree.heading("DNI", text="DNI")
        self.part_tree.heading("Edad", text="Edad")
        self.part_tree.heading("País", text="País")
        
        self.part_tree.pack(fill=tk.BOTH, expand=True)
    
        # Variables para datos consultados
        self.participante_consultado = None
        self.representante_consultado = None
    
    def on_tipo_changed(self, event=None):
        """Cuando cambia el tipo de participante"""
        self.participante_consultado = None
        self.representante_consultado = None
        self.text_datos.delete(1.0, tk.END)
    
    def consultar_cliente_responsable(self):
        """Consultar datos del cliente responsable"""
        cli_id_str = self.entry_cli_responsable.get().strip()
        if not cli_id_str:
            messagebox.showwarning("Error", "Ingresa un ID de cliente")
            return
        
        try:
            cli_id = int(cli_id_str)
            log_event("API", f"Consultando cliente responsable: {cli_id}")
            
            response = requests.get(
                f"{API_BASE_URL}/api/v1/clientes/{cli_id}",
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 200:
                data = response.json()
                self.cliente_responsable_id = cli_id
                nombre_completo = f"{data.get('cli_pnombre', '')} {data.get('cli_papellido', '')} {data.get('cli_sapellido', '')}"
                self.label_cli_responsable.config(
                    text=f"✓ {nombre_completo} (ID: {cli_id}, Edad: {data.get('edad_calculada', 'N/A')})",
                    foreground="green"
                )
                log_event("SUCCESS", f"Cliente responsable consultado: {nombre_completo}")
            else:
                error_msg = response.json().get('error', 'Error desconocido')
                self.label_cli_responsable.config(text=f"✗ Error: {error_msg}", foreground="red")
                messagebox.showerror("Error", f"Error consultando cliente: {error_msg}")
        except ValueError:
            messagebox.showerror("Error", "ID debe ser un número")
        except Exception as e:
            log_event("ERROR", str(e))
            messagebox.showerror("Error", f"Error: {e}")
    
    def consultar_participante(self):
        """Consultar datos del participante (cliente o fan LEGO)"""
        if not self.tour_seleccionado:
            messagebox.showwarning("Advertencia", "Selecciona un tour primero")
            return
        
        tipo = self.combo_tipo.get()
        if not tipo:
            messagebox.showwarning("Error", "Selecciona el tipo de participante")
            return
        
        id_str = self.entry_id_participante.get().strip()
        if not id_str:
            messagebox.showwarning("Error", "Ingresa un ID")
            return
        
        try:
            participante_id = int(id_str)
            
            def _consultar():
                try:
                    if tipo == "ADULTO":
                        # Consultar cliente
                        log_event("API", f"Consultando cliente: {participante_id}")
                        response = requests.get(
                            f"{API_BASE_URL}/api/v1/clientes/{participante_id}",
                            timeout=API_TIMEOUT
                        )
                        
                        if response.status_code == 200:
                            data = response.json()
                            self.participante_consultado = {
                                "tipo": "ADULTO",
                                "id": participante_id,
                                "datos": data
                            }
                            self.representante_consultado = None
                            
                            nombre = f"{data.get('cli_pnombre', '')} {data.get('cli_papellido', '')} {data.get('cli_sapellido', '')}"
                            info = f"""DATOS DEL CLIENTE (ADULTO):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: {participante_id}
Nombre: {nombre}
DNI: {data.get('cli_dni', 'N/A')}
Fecha Nacimiento: {data.get('cli_fnacimiento', 'N/A')}
Edad: {data.get('edad_calculada', 'N/A')} años
País: {data.get('pais_nombre', 'N/A')}
Pertenece UE: {data.get('pais_pertenece_ue', 'NO')}
Pasaporte: {data.get('cli_numpas', 'No requerido')}
Vencimiento Pasaporte: {data.get('cli_fvenpas', 'N/A')}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"""
                            
                            self.root.after(0, lambda: self._mostrar_datos_consultados(info))
                        else:
                            error_msg = response.json().get('error', 'Error desconocido')
                            self.root.after(0, lambda: messagebox.showerror("Error", f"Error consultando cliente: {error_msg}"))
                    
                    elif tipo == "MENOR":
                        # Consultar fan LEGO
                        log_event("API", f"Consultando fan LEGO: {participante_id}")
                        response = requests.get(
                            f"{API_BASE_URL}/api/v1/fans-lego/{participante_id}",
                            timeout=API_TIMEOUT
                        )
                        
                        if response.status_code == 200:
                            data = response.json()
                            self.participante_consultado = {
                                "tipo": "MENOR",
                                "id": participante_id,
                                "datos": data
                            }
                            
                            # Obtener datos del representante automáticamente
                            rep_id = data.get('rep_cli_id')
                            if rep_id:
                                log_event("API", f"Consultando representante: {rep_id}")
                                rep_response = requests.get(
                                    f"{API_BASE_URL}/api/v1/clientes/{rep_id}",
                                    timeout=API_TIMEOUT
                                )
                                if rep_response.status_code == 200:
                                    self.representante_consultado = {
                                        "id": rep_id,
                                        "datos": rep_response.json()
                                    }
                            
                            nombre_fan = f"{data.get('fl_pnombre', '')} {data.get('fl_papellido', '')} {data.get('fl_sapellido', '')}"
                            nombre_rep = ""
                            if self.representante_consultado:
                                rep_data = self.representante_consultado['datos']
                                nombre_rep = f"{rep_data.get('cli_pnombre', '')} {rep_data.get('cli_papellido', '')} {rep_data.get('cli_sapellido', '')}"
                            
                            info = f"""DATOS DEL FAN LEGO (MENOR):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: {participante_id}
Nombre: {nombre_fan}
DNI: {data.get('fl_dni', 'N/A')}
Fecha Nacimiento: {data.get('fl_fnacimiento', 'N/A')}
Edad: {data.get('edad_fan', 'N/A')} años
País: {data.get('pais_fan_nombre', 'N/A')}
Pertenece UE: {data.get('pais_fan_ue', 'NO')}
Pasaporte: {data.get('fl_numpas', 'No requerido')}
Vencimiento Pasaporte: {data.get('fl_fvenpas', 'N/A')}

DATOS DEL REPRESENTANTE (AUTOMÁTICO):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"""
                            
                            if self.representante_consultado:
                                rep_data = self.representante_consultado['datos']
                                info += f"""
ID: {rep_id}
Nombre: {nombre_rep}
DNI: {rep_data.get('cli_dni', 'N/A')}
Fecha Nacimiento: {rep_data.get('cli_fnacimiento', 'N/A')}
Edad: {rep_data.get('edad_calculada', 'N/A')} años
País: {rep_data.get('pais_nombre', 'N/A')}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"""
                            else:
                                info += "\n⚠️ No se encontró representante asignado"
                            
                            self.root.after(0, lambda: self._mostrar_datos_consultados(info))
                        else:
                            error_msg = response.json().get('error', 'Error desconocido')
                            self.root.after(0, lambda: messagebox.showerror("Error", f"Error consultando fan LEGO: {error_msg}"))
                
                except Exception as e:
                    self.root.after(0, lambda: messagebox.showerror("Error", f"Error: {e}"))
            
            thread = threading.Thread(target=_consultar, daemon=True)
            thread.start()
            
        except ValueError:
            messagebox.showerror("Error", "ID debe ser un número")
    
    def _mostrar_datos_consultados(self, info):
        """Mostrar datos consultados en el área de texto"""
        self.text_datos.delete(1.0, tk.END)
        self.text_datos.insert(tk.END, info)
    
    def agregar_participante(self):
        """Agregar participante consultado a la inscripción"""
        if not self.tour_seleccionado:
            messagebox.showwarning("Advertencia", "Selecciona un tour primero")
            return
        
        if not self.participante_consultado:
            messagebox.showwarning("Error", "Consulta los datos del participante primero")
            return
        
        # Validar cupos
        if len(self.participantes_agregados) >= self.tour_seleccionado['cupos_disponibles']:
            messagebox.showwarning("Error", "No hay cupos disponibles para más participantes")
            return
        
        # Agregar participante
        participante = {
            "numero": len(self.participantes_agregados) + 1,
            "tipo": self.participante_consultado["tipo"],
            "id": self.participante_consultado["id"],
            "datos": self.participante_consultado["datos"]
        }
        
        # Si es fan LEGO y tiene representante, agregarlo también si no está ya agregado
        if self.participante_consultado["tipo"] == "MENOR" and self.representante_consultado:
            rep_id = self.representante_consultado["id"]
            # Verificar si el representante ya está agregado
            rep_ya_agregado = any(p.get("id") == rep_id for p in self.participantes_agregados)
            if not rep_ya_agregado:
                # Agregar representante como ADULTO
                rep_data = self.representante_consultado["datos"]
                rep_participante = {
                    "numero": len(self.participantes_agregados) + 2,
                    "tipo": "ADULTO",
                    "id": rep_id,
                    "datos": rep_data
                }
                self.participantes_agregados.append(rep_participante)
                
                # Agregar a la tabla
                nombre_rep = f"{rep_data.get('cli_pnombre', '')} {rep_data.get('cli_papellido', '')} {rep_data.get('cli_sapellido', '')}"
                self.part_tree.insert(
                    "",
                    tk.END,
                    values=(
                        rep_participante["numero"],
                        "ADULTO",
                        rep_id,
                        nombre_rep,
                        rep_data.get('cli_dni', 'N/A'),
                        rep_data.get('edad_calculada', 'N/A'),
                        rep_data.get('pais_nombre', 'N/A')
                    )
                )
        
        self.participantes_agregados.append(participante)
        
        # Agregar a la tabla
        datos = participante["datos"]
        if participante["tipo"] == "ADULTO":
            nombre = f"{datos.get('cli_pnombre', '')} {datos.get('cli_papellido', '')} {datos.get('cli_sapellido', '')}"
            dni = datos.get('cli_dni', 'N/A')
            edad = datos.get('edad_calculada', 'N/A')
            pais = datos.get('pais_nombre', 'N/A')
        else:  # MENOR
            nombre = f"{datos.get('fl_pnombre', '')} {datos.get('fl_papellido', '')} {datos.get('fl_sapellido', '')}"
            dni = datos.get('fl_dni', 'N/A')
            edad = datos.get('edad_fan', 'N/A')
            pais = datos.get('pais_fan_nombre', 'N/A')
        
        self.part_tree.insert(
            "",
            tk.END,
            values=(
                participante["numero"],
                participante["tipo"],
                participante["id"],
                nombre,
                dni,
                edad,
                pais
            )
        )
        
        log_event("PART", f"Participante agregado: {nombre} (ID: {participante['id']}, Tipo: {participante['tipo']})")
        self.limpiar_participante()
        
        # Actualizar label
        self.label_part_tour.config(
            text=f"✓ {len(self.participantes_agregados)} participante(s) agregado(s)",
            foreground="green"
        )
    
    def limpiar_participante(self):
        """Limpia el formulario de consulta de participante"""
        self.entry_id_participante.delete(0, tk.END)
        self.text_datos.delete(1.0, tk.END)
        self.participante_consultado = None
        self.representante_consultado = None

    
    def crear_pestaña_resumen(self):
        """Pestaña 3: Resumen e Inscripción"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="4️ Resumen")
        
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
        
        self.label_costo_unitario = ttk.Label(cost_frame, text="Costo unitario: 0.00 DKK")
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
                     f"Costo: {self.tour_seleccionado['costo_unitario']:.2f} DKK",
                foreground="green"
            )
        
        cantidad = len(self.participantes_agregados)
        self.label_res_part.config(text=f"{cantidad} participante(s)")
        self.label_cantidad_participantes.config(text=f"Participantes: {cantidad}")
        
        if self.tour_seleccionado and cantidad > 0:
            self.label_costo_unitario.config(
                text=f"Costo unitario: {self.tour_seleccionado['costo_unitario']:.2f} DKK"
            )
            costo_total_dkk = self.tour_seleccionado['costo_unitario'] * cantidad
            # El costo total se mostrará en la moneda correcta cuando se cree la inscripción
            self.label_costo_total.config(text=f"COSTO TOTAL (DKK): {costo_total_dkk:,.2f}")
        else:
            self.label_costo_total.config(text="COSTO TOTAL: 0.00 DKK")
    
    def crear_inscripcion(self):
        """Crear inscripción en BD usando sp_crear_inscripcion"""
        if not self.tour_seleccionado or len(self.participantes_agregados) == 0:
            messagebox.showwarning("Error", "Selecciona tour y agrega participantes")
            return

        if not self.cliente_responsable_id:
            messagebox.showwarning("Error", "Debes consultar y seleccionar un cliente responsable")
            return
        
        # Construir participantes_json según el formato: "ADULTO:cli_id;MENOR:fl_id;..."
        participantes_parts = []
        for p in self.participantes_agregados:
            tipo = p["tipo"]
            p_id = p["id"]
            participantes_parts.append(f"{tipo}:{p_id}")
        
        participantes_json = ";".join(participantes_parts)

        try:
            payload = {
                "tour_fecha": self.tour_seleccionado['fecha'],
                "cliente_responsable": self.cliente_responsable_id,
                "participantes_json": participantes_json
            }

            log_event("API", f"Creando inscripción vía sp_crear_inscripcion...")
            log_event("API", f"Participantes: {participantes_json}")
            response = requests.post(
                f"{API_BASE_URL}/api/v1/inscripciones/crear",
                json=payload,
                timeout=API_TIMEOUT
            )

            if response.status_code == 201:
                resultado = response.json()
                self.inscripcion_actual = resultado
                log_event("SUCCESS", f"Inscripción creada: {resultado.get('ins_num')} - Estado: PENDIENTE")
                
                # Actualizar información de pago antes de cambiar de pestaña
                self.actualizar_info_pago()
                
                # Obtener moneda para mostrar
                moneda = resultado.get('moneda', 'USD')
                simbolo = "€" if moneda == "EUR" else "$"
                monto = resultado.get('ins_total', 0)
                
                messagebox.showinfo("Éxito", 
                    f"✓ Inscripción creada exitosamente\n\n"
                    f"Número: {resultado.get('ins_num')}\n"
                    f"Total: {simbolo}{monto:,.2f} {moneda}\n"
                    f"Estado: PENDIENTE POR PAGAR\n\n"
                    f"Procede al pago para confirmar.")
                self.notebook.select(4)  # Ir a pestaña de pago
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
        self.notebook.add(frame, text="5️ Pago")
        
        # Título
        ttk.Label(frame, text="💳 Procesar Pago", font=("Arial", 16, "bold")).pack(pady=15)
        
        # Actualizar info de inscripción cuando se muestra esta pestaña
        def on_tab_changed(event):
            if self.notebook.index(self.notebook.select()) == 4:  # Pestaña de pago
                self.actualizar_info_pago()
        
        self.notebook.bind("<<NotebookTabChanged>>", on_tab_changed)
        
        # Info inscripción
        info_frame = ttk.LabelFrame(frame, text="Inscripción")
        info_frame.pack(fill=tk.X, padx=10, pady=10)
        
        self.label_insc_num = ttk.Label(info_frame, text="Inscripción: No creada")
        self.label_insc_num.pack(pady=5)
        
        self.label_insc_estado = ttk.Label(info_frame, text="Estado: -", foreground="orange")
        self.label_insc_estado.pack(pady=5)
        
        self.label_insc_monto = ttk.Label(info_frame, text="Monto a pagar: $0.00", 
                                         font=("Arial", 12, "bold"), foreground="blue")
        self.label_insc_monto.pack(pady=10)
        
        # Método de pago (simplificado - solo para mostrar)
        pay_frame = ttk.LabelFrame(frame, text="Método de Pago")
        pay_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Label(pay_frame, text="Método:").pack(anchor=tk.W, padx=10)
        self.combo_metodo_pago = ttk.Combobox(
            pay_frame,
            values=["TARJETA CRÉDITO", "TARJETA DÉBITO", "TRANSFERENCIA BANCARIA"],
            state="readonly",
            width=40
        )
        self.combo_metodo_pago.set("TARJETA CRÉDITO")  # Valor por defecto
        self.combo_metodo_pago.pack(padx=10, pady=5)
        
        # Datos pago (simplificado - solo CVV)
        datos_frame = ttk.LabelFrame(frame, text="Datos de Pago")
        datos_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Label(datos_frame, text="CVV de la Tarjeta:").grid(row=0, column=0, sticky=tk.W, padx=10, pady=8)
        self.entry_cvv = ttk.Entry(datos_frame, width=10, show="*")
        self.entry_cvv.grid(row=0, column=1, padx=10, pady=8, sticky=tk.W)
        ttk.Label(datos_frame, text="(3 o 4 dígitos)", font=("Arial", 9), foreground="gray").grid(row=0, column=2, sticky=tk.W, padx=5)
        
        # Botones
        button_frame = ttk.Frame(frame)
        button_frame.pack(fill=tk.X, padx=10, pady=15)
        
        ttk.Button(button_frame, text="✓ CONFIRMAR PAGO", 
                  command=self.procesar_pago).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="❌ CANCELAR", 
                  command=self.cancelar_pago).pack(side=tk.LEFT, padx=5)
    
    def procesar_pago(self):
        """Procesar pago usando sp_confirmar_pago_inscripcion (simplificado - solo CVV)"""
        if not self.inscripcion_actual:
            messagebox.showwarning("Error", "No hay inscripción para procesar pago")
            return
        
        # Validar CVV (cualquier 3-4 dígitos)
        cvv = self.entry_cvv.get().strip()
        if not cvv:
            messagebox.showwarning("Error", "Ingresa el CVV de la tarjeta")
            return
        
        if not cvv.isdigit() or len(cvv) < 3 or len(cvv) > 4:
            messagebox.showwarning("Error", "El CVV debe tener 3 o 4 dígitos")
            return
        
        try:
            ins_num = self.inscripcion_actual.get('ins_num')
            monto_total = self.inscripcion_actual.get('ins_total', 0)
            moneda = self.inscripcion_actual.get('moneda', 'USD')
            metodo = self.combo_metodo_pago.get() or "TARJETA CRÉDITO"
            
            # Si el monto es 0, obtenerlo de la inscripción en la BD
            if monto_total == 0:
                # El backend ya maneja esto, pero por si acaso
                pass
            
            # Generar referencia de pago
            referencia_pago = f"{metodo}-{ins_num}-{datetime.now().strftime('%Y%m%d%H%M%S')}"
            
            payload = {
                "inscripcion_num": ins_num,
                "moneda_pago": moneda,
                "monto_pagado": monto_total,
                "referencia_pago": referencia_pago
            }
            
            log_event("API", f"Confirmando pago de inscripción {ins_num}...")
            
            response = requests.post(
                f"{API_BASE_URL}/api/v1/pagos/confirmar",
                json=payload,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 200:
                resultado = response.json()
                self.estado_pago = "PAGO"
                self.inscripcion_actual.update(resultado)
                
                log_event("SUCCESS", f"Pago confirmado - Recibo: {resultado.get('recibo')}")
                log_event("SUCCESS", f"Entradas generadas: {resultado.get('entradas_generadas')}")
                
                # Obtener número de entradas (del resultado del pago o de la inscripción original)
                entradas_pago = resultado.get('entradas_generadas', 0)
                entradas_inscripcion = self.inscripcion_actual.get('entradas_generadas', 0)
                cantidad_participantes = self.inscripcion_actual.get('cantidad_participantes', 0)
                
                # Usar el valor del pago si es > 0, sino usar el de la inscripción, sino usar cantidad de participantes
                entradas_finales = entradas_pago if entradas_pago > 0 else (entradas_inscripcion if entradas_inscripcion > 0 else cantidad_participantes)
                
                # Actualizar el valor en inscripcion_actual para que se muestre correctamente
                self.inscripcion_actual['entradas_generadas'] = entradas_finales
                
                messagebox.showinfo("Éxito", 
                    f"✓ Pago confirmado exitosamente\n\n"
                    f"Recibo: {resultado.get('recibo')}\n"
                    f"Entradas generadas: {entradas_finales}\n"
                    f"Estado: PAGO\n\n"
                    f"Las entradas han sido generadas automáticamente.")
                self.notebook.select(5)  # Ir a confirmación
                self.actualizar_confirmacion()
            else:
                error_msg = response.json().get('error', f"Error {response.status_code}")
                log_event("ERROR", error_msg)
                messagebox.showerror("Error", f"Error procesando pago: {error_msg}")
        
        except Exception as e:
            log_event("ERROR", str(e))
            messagebox.showerror("Error", f"Error: {e}")
    
    def actualizar_info_pago(self):
        """Actualizar información de inscripción en pestaña de pago"""
        if self.inscripcion_actual:
            ins_num = self.inscripcion_actual.get('ins_num')
            monto = self.inscripcion_actual.get('ins_total', 0)
            estado = self.inscripcion_actual.get('estado', 'PENDIENTE')
            moneda = self.inscripcion_actual.get('moneda', 'USD')
            
            # Símbolo de moneda
            simbolo = "€" if moneda == "EUR" else "$"
            
            self.label_insc_num.config(text=f"Inscripción: #{ins_num}")
            self.label_insc_estado.config(
                text=f"Estado: {estado}",
                foreground="orange" if estado == "PENDIENTE" else "green"
            )
            self.label_insc_monto.config(text=f"Monto a pagar: {simbolo}{monto:,.2f} {moneda}")
        else:
            self.label_insc_num.config(text="Inscripción: No creada")
            self.label_insc_estado.config(text="Estado: -")
            self.label_insc_monto.config(text="Monto a pagar: $0.00")
    
    def cancelar_pago(self):
        """Cancelar pago"""
        messagebox.showinfo("Cancelado", "Pago cancelado. Puedes intentar de nuevo.")
        self.limpiar_pago()
    
    def limpiar_pago(self):
        """Limpiar form pago"""
        self.combo_metodo_pago.set("TARJETA CRÉDITO")
        self.entry_cvv.delete(0, tk.END)
    
    def crear_pestaña_confirmacion(self):
        """Pestaña 5: Confirmación Final"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="6 Confirmación")
        
        # Título
        ttk.Label(frame, text="✅ Confirmación de Inscripción", font=("Arial", 16, "bold")).pack(pady=15)
        
        # Actualizar confirmación cuando se muestra esta pestaña
        def on_tab_changed(event):
            if self.notebook.index(self.notebook.select()) == 5:  # Pestaña de confirmación
                self.actualizar_confirmacion()
        
        self.notebook.bind("<<NotebookTabChanged>>", on_tab_changed)
        
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
        
        ttk.Button(button_frame, text="💾 GUARDAR INSCRIPCIÓN", 
                  command=self.guardar_inscripcion).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="🔄 NUEVA INSCRIPCIÓN", 
                  command=self.nueva_inscripcion).pack(side=tk.LEFT, padx=5)
    
    def actualizar_confirmacion(self):
        """Actualizar información de confirmación"""
        if self.inscripcion_actual:
            comprobante = self.generar_comprobante()
            self.label_conf.delete(1.0, tk.END)
            self.label_conf.insert(tk.END, comprobante)
    
    def guardar_inscripcion(self):
        """Guardar inscripción en la base de datos"""
        if not self.inscripcion_actual:
            messagebox.showwarning("Error", "No hay inscripción para guardar")
            return
        
        ins_num = self.inscripcion_actual.get('ins_num')
        if ins_num is None or ins_num == -1:
            messagebox.showerror("Error", "La inscripción no se creó correctamente. Por favor, crea la inscripción primero.")
            return
        
        # La inscripción ya se guarda automáticamente cuando se crea
        # Este botón solo confirma que está guardada
        messagebox.showinfo("Inscripción Guardada", 
            f"✓ La inscripción #{ins_num} está guardada en la base de datos.\n\n"
            f"Estado: {self.inscripcion_actual.get('estado', 'PENDIENTE')}\n"
            f"Total: {self.inscripcion_actual.get('ins_total', 0):,.2f} {self.inscripcion_actual.get('moneda', 'USD')}")
        
        # Actualizar el comprobante
        comprobante = self.generar_comprobante()
        self.label_conf.delete(1.0, tk.END)
        self.label_conf.insert(tk.END, comprobante)
    
    def generar_comprobante(self):
        """Generar comprobante de inscripción"""
        if not self.inscripcion_actual:
            return "No hay datos de inscripción"
        
        ins_num = self.inscripcion_actual.get('ins_num', 'N/A')
        ins_total = self.inscripcion_actual.get('ins_total', 0)
        estado = self.inscripcion_actual.get('estado', self.estado_pago)
        recibo = self.inscripcion_actual.get('recibo', 'N/A')
        entradas = self.inscripcion_actual.get('entradas_generadas', 0)
        moneda = self.inscripcion_actual.get('moneda', 'USD')
        simbolo = "€" if moneda == "EUR" else "$"
        precio_unitario = self.inscripcion_actual.get('precio_unitario', 0)
        precio_unitario_dkk = self.tour_seleccionado['costo_unitario'] if self.tour_seleccionado else 0
        
        comprobante = f"""
╔════════════════════════════════════════════════════════════════╗
║          COMPROBANTE DE INSCRIPCIÓN - LEGO STORE TOURS        ║
╚════════════════════════════════════════════════════════════════╝

DATOS DE INSCRIPCIÓN:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Número de Inscripción: {ins_num}
Fecha de Emisión: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Estado: {estado}
"""
        
        if estado == "PAGO":
            comprobante += f"""
Recibo: {recibo}
Entradas Generadas: {entradas}
"""
        
        comprobante += f"""
TOUR CONTRATADO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Fecha de Salida: {self.tour_seleccionado['fecha'] if self.tour_seleccionado else 'N/A'}
Costo Unitario: {precio_unitario_dkk:.2f} DKK ({simbolo}{precio_unitario:.2f} {moneda})
Total Participantes: {len(self.participantes_agregados)}

PARTICIPANTES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
        
        for i, p in enumerate(self.participantes_agregados, 1):
            datos = p.get('datos', {})
            if p['tipo'] == "ADULTO":
                nombre = f"{datos.get('cli_pnombre', '')} {datos.get('cli_papellido', '')} {datos.get('cli_sapellido', '')}"
                dni = datos.get('cli_dni', 'N/A')
                edad = datos.get('edad_calculada', 'N/A')
                pais = datos.get('pais_nombre', 'N/A')
            else:  # MENOR
                nombre = f"{datos.get('fl_pnombre', '')} {datos.get('fl_papellido', '')} {datos.get('fl_sapellido', '')}"
                dni = datos.get('fl_dni', 'N/A')
                edad = datos.get('edad_fan', 'N/A')
                pais = datos.get('pais_fan_nombre', 'N/A')
            
            comprobante += f"""
{i}. {nombre}
   Tipo: {p['tipo']}
   ID: {p['id']}
   DNI: {dni}
   Edad: {edad} años
   País: {pais}
"""
        
        comprobante += f"""
CÁLCULO DE COSTO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{precio_unitario_dkk:.2f} DKK × {len(self.participantes_agregados)} participantes = {precio_unitario_dkk * len(self.participantes_agregados):,.2f} DKK
({simbolo}{precio_unitario:.2f} {moneda} × {len(self.participantes_agregados)} = {simbolo}{ins_total:,.2f} {moneda})

TOTAL PAGADO: {simbolo}{ins_total:,.2f} {moneda}

════════════════════════════════════════════════════════════════
"""

        if estado == "PAGO":
            comprobante += f"""
✓ INSCRIPCIÓN CONFIRMADA Y PAGADA
✓ ENTRADAS GENERADAS: {entradas}
📅 Fecha del tour: {self.tour_seleccionado['fecha'] if self.tour_seleccionado else 'N/A'}

Gracias por tu confianza. ¡Que disfrutes el tour!
"""
        else:
            comprobante += f"""
⚠️ INSCRIPCIÓN PENDIENTE DE PAGO
📅 Fecha de viaje: {self.tour_seleccionado['fecha'] if self.tour_seleccionado else 'N/A'}

Por favor, procede al pago para confirmar tu inscripción.
"""
        
        return comprobante
    
    def nueva_inscripcion(self):
        """Iniciar nueva inscripción - limpiar todo el proceso"""
        # Limpiar datos de inscripción
        self.tour_seleccionado = None
        self.fecha_tour_seleccionada = None
        self.participantes_agregados = []
        self.inscripcion_actual = None
        self.cliente_responsable_id = None
        self.estado_pago = "PENDIENTE"
        self.participante_consultado = None
        self.representante_consultado = None
        
        # Limpiar interfaz de tours
        self.notebook.select(0)  # Volver a tours
        if hasattr(self, 'label_tour_info'):
            self.label_tour_info.config(text="Tour: No seleccionado", foreground="red")
        if hasattr(self, 'label_part_tour'):
            self.label_part_tour.config(text="No seleccionado", foreground="red")
        
        # Limpiar interfaz de participantes
        if hasattr(self, 'entry_cli_responsable'):
            self.entry_cli_responsable.delete(0, tk.END)
        if hasattr(self, 'label_cli_responsable'):
            self.label_cli_responsable.config(text="No consultado", foreground="red")
        if hasattr(self, 'entry_participante_id'):
            self.entry_participante_id.delete(0, tk.END)
        if hasattr(self, 'text_datos'):
            self.text_datos.delete(1.0, tk.END)
        if hasattr(self, 'tree_participantes'):
            for item in self.tree_participantes.get_children():
                self.tree_participantes.delete(item)
        if hasattr(self, 'part_tree'):
            for item in self.part_tree.get_children():
                self.part_tree.delete(item)
        
        # Limpiar resumen
        if hasattr(self, 'label_res_tour'):
            self.label_res_tour.config(text="Tour: No seleccionado", foreground="red")
        if hasattr(self, 'label_res_part'):
            self.label_res_part.config(text="0 participante(s)")
        if hasattr(self, 'label_costo_unitario'):
            self.label_costo_unitario.config(text="Costo unitario: 0.00 DKK")
        if hasattr(self, 'label_cantidad_participantes'):
            self.label_cantidad_participantes.config(text="Participantes: 0")
        if hasattr(self, 'label_costo_total'):
            self.label_costo_total.config(text="COSTO TOTAL: 0.00 DKK")
        
        # Limpiar pago
        if hasattr(self, 'label_insc_num'):
            self.label_insc_num.config(text="Inscripción: No creada")
        if hasattr(self, 'label_insc_estado'):
            self.label_insc_estado.config(text="Estado: -")
        if hasattr(self, 'label_insc_monto'):
            self.label_insc_monto.config(text="Monto a pagar: $0.00")
        if hasattr(self, 'entry_cvv'):
            self.entry_cvv.delete(0, tk.END)
        if hasattr(self, 'combo_metodo_pago'):
            self.combo_metodo_pago.set("TARJETA CRÉDITO")
        
        # Limpiar confirmación
        if hasattr(self, 'label_conf'):
            self.label_conf.delete(1.0, tk.END)
        
        messagebox.showinfo("Nueva Inscripción", "Proceso limpiado. Puedes iniciar una nueva inscripción.")

    # ═══════════════════════════════════════════════════════════════════════════════
    # VENTAS TIENDA FÍSICA
    # ═══════════════════════════════════════════════════════════════════════════════
    
    def crear_pestaña_ventas_fisicas(self):
        """Crear pestaña para ventas de tienda física"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="🏪 Tienda Física")
        
        # Título
        ttk.Label(frame, text="🏪 Ventas Tienda Física", font=("Arial", 16, "bold")).pack(pady=15)
        
        # Variables de estado
        self.tienda_seleccionada = None
        self.factura_fisica_actual = None
        self.detalles_factura_fisica = []
        self.catalogo_tienda = []
        
        # Frame principal con scroll
        canvas = tk.Canvas(frame, highlightthickness=0)
        scrollbar = ttk.Scrollbar(frame, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)
        
        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        # Paso 1: Seleccionar Tienda
        paso1_frame = ttk.LabelFrame(scrollable_frame, text="1️ Seleccionar Tienda y Cliente")
        paso1_frame.pack(fill=tk.X, padx=20, pady=10)
        
        ttk.Label(paso1_frame, text="Tienda:").grid(row=0, column=0, padx=5, pady=5, sticky="w")
        self.combo_tienda_fisica = ttk.Combobox(paso1_frame, state="readonly", width=40)
        self.combo_tienda_fisica.grid(row=0, column=1, padx=5, pady=5)
        self.combo_tienda_fisica.bind("<<ComboboxSelected>>", self._on_tienda_seleccionada_fisica)
        
        ttk.Button(paso1_frame, text="Cargar Tiendas", command=self.cargar_tiendas).grid(row=0, column=2, padx=5, pady=5)
        
        ttk.Label(paso1_frame, text="ID Cliente:").grid(row=1, column=0, padx=5, pady=5, sticky="w")
        self.entry_cliente_fisica = ttk.Entry(paso1_frame, width=20)
        self.entry_cliente_fisica.grid(row=1, column=1, padx=5, pady=5, sticky="w")
        ttk.Button(paso1_frame, text="Consultar Cliente", command=self.consultar_cliente_fisica).grid(row=1, column=2, padx=5, pady=5)
        
        self.label_info_cliente_fisica = ttk.Label(paso1_frame, text="", foreground="blue")
        self.label_info_cliente_fisica.grid(row=2, column=0, columnspan=3, padx=5, pady=5, sticky="w")
        
        # Horarios de la tienda
        self.label_horarios = ttk.Label(paso1_frame, text="", foreground="gray")
        self.label_horarios.grid(row=3, column=0, columnspan=3, padx=5, pady=5, sticky="w")
        
        # Paso 2: Catálogo y Productos
        paso2_frame = ttk.LabelFrame(scrollable_frame, text="2️ Inventario de Productos")
        paso2_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
        
        # Treeview para productos
        tree_frame = ttk.Frame(paso2_frame)
        tree_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        columns = ("Código", "Producto", "Precio", "Stock Total", "Lotes")
        self.tree_productos_fisica = ttk.Treeview(tree_frame, columns=columns, show="headings", height=10)
        
        for col in columns:
            self.tree_productos_fisica.heading(col, text=col)
            self.tree_productos_fisica.column(col, width=120)
        
        scrollbar_tree = ttk.Scrollbar(tree_frame, orient="vertical", command=self.tree_productos_fisica.yview)
        self.tree_productos_fisica.configure(yscrollcommand=scrollbar_tree.set)
        
        self.tree_productos_fisica.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar_tree.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Paso 3: Agregar Productos a Factura
        paso3_frame = ttk.LabelFrame(scrollable_frame, text="3 Agregar Productos a Factura")
        paso3_frame.pack(fill=tk.X, padx=20, pady=10)
        
        ttk.Label(paso3_frame, text="Código Producto:").grid(row=0, column=0, padx=5, pady=5, sticky="w")
        self.entry_prod_cod_fisica = ttk.Entry(paso3_frame, width=15)
        self.entry_prod_cod_fisica.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(paso3_frame, text="Cantidad:").grid(row=0, column=2, padx=5, pady=5, sticky="w")
        self.entry_cantidad_fisica = ttk.Entry(paso3_frame, width=10)
        self.entry_cantidad_fisica.grid(row=0, column=3, padx=5, pady=5)
        
        ttk.Button(paso3_frame, text="Agregar a Factura", command=self.agregar_detalle_fisica).grid(row=0, column=4, padx=5, pady=5)
        ttk.Button(paso3_frame, text="Iniciar Factura", command=self.iniciar_factura_fisica).grid(row=0, column=5, padx=5, pady=5)
        
        # Lista de detalles
        detalles_frame = ttk.Frame(paso3_frame)
        detalles_frame.grid(row=1, column=0, columnspan=6, padx=5, pady=5, sticky="ew")
        
        ttk.Label(detalles_frame, text="Detalles de Factura:").pack(anchor="w")
        
        self.listbox_detalles_fisica = tk.Listbox(detalles_frame, height=5)
        self.listbox_detalles_fisica.pack(fill=tk.X, pady=5)
        
        # Paso 4: Finalizar Factura
        paso4_frame = ttk.LabelFrame(scrollable_frame, text="4 Finalizar Factura")
        paso4_frame.pack(fill=tk.X, padx=20, pady=10)
        
        self.label_total_fisica = ttk.Label(paso4_frame, text="Total: $0.00", font=("Arial", 12, "bold"))
        self.label_total_fisica.pack(pady=10)
        
        ttk.Button(paso4_frame, text="Finalizar y Guardar Factura", command=self.finalizar_factura_fisica).pack(pady=5)
        ttk.Button(paso4_frame, text="Nueva Venta", command=self.nueva_venta_fisica).pack(pady=5)
        
        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Cargar tiendas al inicio
        self.cargar_tiendas()
    
    def cargar_tiendas(self):
        """Cargar lista de tiendas desde API"""
        def _cargar():
            try:
                log_event("API", "Cargando tiendas...")
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/tiendas",
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    tiendas = response.json()
                    self.tiendas_disponibles = {t["ti_id"]: t for t in tiendas}
                    nombres = [f"{t['ti_id']} - {t['ti_nom']}" for t in tiendas]
                    self.combo_tienda_fisica['values'] = nombres
                    log_event("SUCCESS", f"Tiendas cargadas: {len(tiendas)}")
                else:
                    log_event("ERROR", f"Error cargando tiendas: {response.status_code}")
            except Exception as e:
                log_event("ERROR", str(e))
        
        thread = threading.Thread(target=_cargar, daemon=True)
        thread.start()
    
    def _on_tienda_seleccionada_fisica(self, event=None):
        """Cuando se selecciona una tienda"""
        seleccion = self.combo_tienda_fisica.get()
        if seleccion:
            try:
                tienda_id = int(seleccion.split(" - ")[0])
                self.tienda_seleccionada = tienda_id
                log_event("INFO", f"Tienda seleccionada: {tienda_id}")
                # Cargar catálogo y horarios automáticamente
                self.cargar_catalogo_tienda(tienda_id)
                self.cargar_horarios_tienda(tienda_id)
            except (ValueError, IndexError) as e:
                log_event("ERROR", f"Error parseando tienda: {e}")
                messagebox.showerror("Error", "Error al seleccionar tienda")
    
    def cargar_horarios_tienda(self, tienda_id):
        """Cargar horarios de la tienda"""
        def _cargar():
            try:
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/tiendas/{tienda_id}/horarios",
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    horarios = response.json()
                    dias_semana = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
                    texto = "Horarios: " + ", ".join([
                        f"{dias_semana[h['dia_numero']-1]} {h['hora_apertura']}-{h['hora_cierre']}"
                        for h in horarios
                    ])
                    self.label_horarios.config(text=texto)
            except Exception as e:
                log_event("ERROR", str(e))
        
        thread = threading.Thread(target=_cargar, daemon=True)
        thread.start()
    
    def cargar_catalogo_tienda(self, tienda_id):
        """Cargar catálogo de productos de la tienda"""
        def _cargar():
            try:
                log_event("API", f"Cargando catálogo tienda {tienda_id}...")
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/tiendas/{tienda_id}/catalogo",
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    self.catalogo_tienda = response.json()
                    
                    # Limpiar tree
                    for item in self.tree_productos_fisica.get_children():
                        self.tree_productos_fisica.delete(item)
                    
                    # Agregar productos
                    for producto in self.catalogo_tienda:
                        stock_total = sum(l["stock_disponible"] for l in producto["lotes"])
                        lotes_info = f"{len(producto['lotes'])} lotes"
                        self.tree_productos_fisica.insert("", tk.END, values=(
                            producto["pro_cod"],
                            producto["pro_nom"],
                            f"${producto['precio']:.2f}",
                            stock_total,
                            lotes_info
                        ))
                    
                    log_event("SUCCESS", f"Catálogo cargado: {len(self.catalogo_tienda)} productos")
                else:
                    log_event("ERROR", f"Error cargando catálogo: {response.status_code}")
            except Exception as e:
                log_event("ERROR", str(e))
        
        thread = threading.Thread(target=_cargar, daemon=True)
        thread.start()
    
    def consultar_cliente_fisica(self):
        """Consultar información del cliente"""
        cli_id = self.entry_cliente_fisica.get().strip()
        if not cli_id:
            messagebox.showwarning("Advertencia", "Ingresa un ID de cliente")
            return
        
        def _consultar():
            try:
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/clientes/{cli_id}",
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    cliente = response.json()
                    # Construir nombre completo
                    nombre = cliente.get('nombre_completo', '')
                    if not nombre or nombre.strip() == '':
                        nombre = f"{cliente.get('cli_pnombre', '')} {cliente.get('cli_papellido', '')} {cliente.get('cli_sapellido', '')}".strip()
                    if not nombre:
                        nombre = 'N/A'
                    
                    # Obtener DNI
                    dni = cliente.get('dni') or cliente.get('cli_dni')
                    if dni is None:
                        dni = 'N/A'
                    
                    texto = f"Cliente: {nombre} | DNI: {dni}"
                    self.label_info_cliente_fisica.config(text=texto, foreground="green")
                    log_event("SUCCESS", f"Cliente consultado: {nombre} (ID: {cli_id})")
                else:
                    error_msg = response.json().get("error", "Cliente no encontrado")
                    self.label_info_cliente_fisica.config(text=f"Error: {error_msg}", foreground="red")
                    log_event("ERROR", f"Error consultando cliente {cli_id}: {error_msg}")
            except Exception as e:
                log_event("ERROR", f"Error consultando cliente: {e}")
                self.label_info_cliente_fisica.config(text=f"Error: {str(e)}", foreground="red")
        
        thread = threading.Thread(target=_consultar, daemon=True)
        thread.start()
    
    def iniciar_factura_fisica(self):
        """Iniciar una nueva factura física"""
        cli_id = self.entry_cliente_fisica.get().strip()
        if not cli_id or not self.tienda_seleccionada:
            messagebox.showwarning("Advertencia", "Selecciona tienda e ingresa ID de cliente")
            return
        
        def _iniciar():
            try:
                response = requests.post(
                    f"{API_BASE_URL}/api/v1/facturas-fisicas/iniciar",
                    json={
                        "cliente_id": int(cli_id),
                        "tienda_id": self.tienda_seleccionada
                    },
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 201:
                    data = response.json()
                    self.factura_fisica_actual = data["fact_num"]
                    self.detalles_factura_fisica = []
                    self.listbox_detalles_fisica.delete(0, tk.END)
                    messagebox.showinfo("Éxito", f"Factura {self.factura_fisica_actual} iniciada")
                    log_event("SUCCESS", f"Factura física iniciada: {self.factura_fisica_actual}")
                else:
                    error = response.json().get("error", "Error desconocido")
                    messagebox.showerror("Error", error)
            except Exception as e:
                log_event("ERROR", str(e))
                messagebox.showerror("Error", str(e))
        
        thread = threading.Thread(target=_iniciar, daemon=True)
        thread.start()
    
    def agregar_detalle_fisica(self):
        """Agregar un detalle a la factura física"""
        if not self.factura_fisica_actual:
            messagebox.showwarning("Advertencia", "Primero inicia una factura")
            return
        
        pro_cod = self.entry_prod_cod_fisica.get().strip()
        cantidad = self.entry_cantidad_fisica.get().strip()
        
        if not pro_cod or not cantidad:
            messagebox.showwarning("Advertencia", "Ingresa código de producto y cantidad")
            return
        
        try:
            cantidad_int = int(cantidad)
            pro_cod_int = int(pro_cod)
        except ValueError:
            messagebox.showerror("Error", "Cantidad y código deben ser números")
            return
        
        # Validar stock disponible antes de agregar
        producto_encontrado = None
        for producto in self.catalogo_tienda:
            if producto["pro_cod"] == pro_cod_int:
                producto_encontrado = producto
                break
        
        if not producto_encontrado:
            messagebox.showerror("Error", f"Producto {pro_cod_int} no encontrado en el catálogo")
            return
        
        # Calcular stock total disponible
        stock_total = sum(l["stock_disponible"] for l in producto_encontrado["lotes"])
        if cantidad_int > stock_total:
            messagebox.showerror("Error", f"Stock insuficiente. Disponible: {stock_total}, Solicitado: {cantidad_int}")
            return
        
        def _agregar():
            try:
                response = requests.post(
                    f"{API_BASE_URL}/api/v1/facturas-fisicas/{self.factura_fisica_actual}/detalles",
                    json={
                        "tienda_id": self.tienda_seleccionada,
                        "producto_cod": pro_cod_int,
                        "cantidad": cantidad_int
                    },
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    data = response.json()
                    detalle_texto = f"Prod {pro_cod_int} x {cantidad_int} - {data.get('mensaje', '')}"
                    self.listbox_detalles_fisica.insert(tk.END, detalle_texto)
                    self.detalles_factura_fisica.append({
                        "producto": pro_cod_int,
                        "cantidad": cantidad_int
                    })
                    self.entry_prod_cod_fisica.delete(0, tk.END)
                    self.entry_cantidad_fisica.delete(0, tk.END)
                    
                    # Actualizar catálogo para reflejar el nuevo stock
                    self.cargar_catalogo_tienda(self.tienda_seleccionada)
                    
                    log_event("SUCCESS", f"Detalle agregado: {detalle_texto}")
                else:
                    error = response.json().get("error", "Error desconocido")
                    messagebox.showerror("Error", error)
                    log_event("ERROR", f"Error agregando detalle: {error}")
            except Exception as e:
                log_event("ERROR", str(e))
                messagebox.showerror("Error", str(e))
        
        thread = threading.Thread(target=_agregar, daemon=True)
        thread.start()
    
    def finalizar_factura_fisica(self):
        """Finalizar la factura física"""
        if not self.factura_fisica_actual:
            messagebox.showwarning("Advertencia", "No hay factura iniciada")
            return
        
        def _finalizar():
            try:
                response = requests.post(
                    f"{API_BASE_URL}/api/v1/facturas-fisicas/{self.factura_fisica_actual}/finalizar",
                    json={"tienda_id": self.tienda_seleccionada},
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    data = response.json()
                    total = data.get("total", 0)
                    self.label_total_fisica.config(text=f"Total: ${total:.2f}")
                    messagebox.showinfo("Éxito", f"Factura {self.factura_fisica_actual} finalizada\nTotal: ${total:.2f}")
                    log_event("SUCCESS", f"Factura física finalizada: {self.factura_fisica_actual}, Total: ${total:.2f}")
                else:
                    error = response.json().get("error", "Error desconocido")
                    messagebox.showerror("Error", error)
            except Exception as e:
                log_event("ERROR", str(e))
                messagebox.showerror("Error", str(e))
        
        thread = threading.Thread(target=_finalizar, daemon=True)
        thread.start()
    
    def nueva_venta_fisica(self):
        """Limpiar y empezar nueva venta"""
        self.factura_fisica_actual = None
        self.detalles_factura_fisica = []
        self.listbox_detalles_fisica.delete(0, tk.END)
        self.label_total_fisica.config(text="Total: $0.00")
        self.entry_prod_cod_fisica.delete(0, tk.END)
        self.entry_cantidad_fisica.delete(0, tk.END)
        messagebox.showinfo("Nueva Venta", "Proceso limpiado. Puedes iniciar una nueva venta.")

    # ═══════════════════════════════════════════════════════════════════════════════
    # VENTAS ONLINE
    # ═══════════════════════════════════════════════════════════════════════════════
    
    def crear_pestaña_ventas_online(self):
        """Crear pestaña para ventas online"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="🛒 Online")
        
        # Título
        ttk.Label(frame, text="🛒 Ventas Online", font=("Arial", 16, "bold")).pack(pady=15)
        
        # Variables de estado
        self.factura_online_actual = None
        self.detalles_factura_online = []
        self.catalogo_online = []
        self.pais_cliente_online = None
        
        # Frame principal con scroll
        canvas = tk.Canvas(frame, highlightthickness=0)
        scrollbar = ttk.Scrollbar(frame, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)
        
        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        # Paso 1: Seleccionar Cliente
        paso1_frame = ttk.LabelFrame(scrollable_frame, text="1️⃣ Seleccionar Cliente")
        paso1_frame.pack(fill=tk.X, padx=20, pady=10)
        
        ttk.Label(paso1_frame, text="ID Cliente:").grid(row=0, column=0, padx=5, pady=5, sticky="w")
        self.entry_cliente_online = ttk.Entry(paso1_frame, width=20)
        self.entry_cliente_online.grid(row=0, column=1, padx=5, pady=5, sticky="w")
        ttk.Button(paso1_frame, text="Consultar Cliente", command=self.consultar_cliente_online).grid(row=0, column=2, padx=5, pady=5)
        
        self.label_info_cliente_online = ttk.Label(paso1_frame, text="", foreground="blue")
        self.label_info_cliente_online.grid(row=1, column=0, columnspan=3, padx=5, pady=5, sticky="w")
        
        # Paso 2: Catálogo por País
        paso2_frame = ttk.LabelFrame(scrollable_frame, text="2️⃣ Catálogo de Productos (por País del Cliente)")
        paso2_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
        
        # Treeview para productos
        tree_frame = ttk.Frame(paso2_frame)
        tree_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        columns = ("Código", "Producto", "Precio", "Límite Compra")
        self.tree_productos_online = ttk.Treeview(tree_frame, columns=columns, show="headings", height=10)
        
        for col in columns:
            self.tree_productos_online.heading(col, text=col)
            self.tree_productos_online.column(col, width=150)
        
        scrollbar_tree = ttk.Scrollbar(tree_frame, orient="vertical", command=self.tree_productos_online.yview)
        self.tree_productos_online.configure(yscrollcommand=scrollbar_tree.set)
        
        self.tree_productos_online.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar_tree.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Paso 3: Agregar Productos a Factura
        paso3_frame = ttk.LabelFrame(scrollable_frame, text="3️⃣ Agregar Productos a Factura")
        paso3_frame.pack(fill=tk.X, padx=20, pady=10)
        
        ttk.Label(paso3_frame, text="Código Producto:").grid(row=0, column=0, padx=5, pady=5, sticky="w")
        self.entry_prod_cod_online = ttk.Entry(paso3_frame, width=15)
        self.entry_prod_cod_online.grid(row=0, column=1, padx=5, pady=5)
        
        ttk.Label(paso3_frame, text="Cantidad:").grid(row=0, column=2, padx=5, pady=5, sticky="w")
        self.entry_cantidad_online = ttk.Entry(paso3_frame, width=10)
        self.entry_cantidad_online.grid(row=0, column=3, padx=5, pady=5)
        
        ttk.Button(paso3_frame, text="Agregar a Factura", command=self.agregar_detalle_online).grid(row=0, column=4, padx=5, pady=5)
        ttk.Button(paso3_frame, text="Iniciar Factura", command=self.iniciar_factura_online).grid(row=0, column=5, padx=5, pady=5)
        
        # Lista de detalles
        detalles_frame = ttk.Frame(paso3_frame)
        detalles_frame.grid(row=1, column=0, columnspan=6, padx=5, pady=5, sticky="ew")
        
        ttk.Label(detalles_frame, text="Detalles de Factura:").pack(anchor="w")
        
        self.listbox_detalles_online = tk.Listbox(detalles_frame, height=5)
        self.listbox_detalles_online.pack(fill=tk.X, pady=5)
        
        # Paso 4: Finalizar Factura
        paso4_frame = ttk.LabelFrame(scrollable_frame, text="4️⃣ Finalizar Factura y Ver Puntos")
        paso4_frame.pack(fill=tk.X, padx=20, pady=10)
        
        self.label_total_online = ttk.Label(paso4_frame, text="Total: $0.00", font=("Arial", 12, "bold"))
        self.label_total_online.pack(pady=5)
        
        self.label_puntos_online = ttk.Label(paso4_frame, text="Puntos generados: 0 | Puntos totales: 0", font=("Arial", 10))
        self.label_puntos_online.pack(pady=5)
        
        ttk.Button(paso4_frame, text="Finalizar y Guardar Factura", command=self.finalizar_factura_online).pack(pady=5)
        ttk.Button(paso4_frame, text="Nueva Venta", command=self.nueva_venta_online).pack(pady=5)
        
        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
    
    def consultar_cliente_online(self):
        """Consultar información del cliente y cargar catálogo"""
        cli_id = self.entry_cliente_online.get().strip()
        if not cli_id:
            messagebox.showwarning("Advertencia", "Ingresa un ID de cliente")
            return
        
        def _consultar():
            try:
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/clientes/{cli_id}",
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    cliente = response.json()
                    # Obtener país de residencia
                    self.pais_cliente_online = cliente.get("pais_residencia_id") or cliente.get("cli_reside")
                    
                    # Construir nombre completo
                    nombre = cliente.get('nombre_completo', '')
                    if not nombre or nombre.strip() == '':
                        nombre = f"{cliente.get('cli_pnombre', '')} {cliente.get('cli_papellido', '')} {cliente.get('cli_sapellido', '')}".strip()
                    if not nombre:
                        nombre = 'N/A'
                    
                    # Obtener nombre del país
                    pais = cliente.get('pais_residencia', '')
                    if not pais or pais.strip() == '':
                        pais = cliente.get('pais_nombre', 'N/A')
                    
                    texto = f"Cliente: {nombre} | País: {pais}"
                    self.label_info_cliente_online.config(text=texto, foreground="green")
                    log_event("SUCCESS", f"Cliente consultado: {nombre} (ID: {cli_id}), País: {pais} (ID: {self.pais_cliente_online})")
                    
                    # Cargar catálogo del país
                    if self.pais_cliente_online:
                        log_event("INFO", f"Cargando catálogo para país {self.pais_cliente_online}")
                        self.cargar_catalogo_online(self.pais_cliente_online)
                    else:
                        messagebox.showwarning("Advertencia", "El cliente no tiene país de residencia configurado")
                        self.label_info_cliente_online.config(text=f"{texto} - Sin país configurado", foreground="orange")
                else:
                    error_msg = response.json().get("error", "Cliente no encontrado")
                    self.label_info_cliente_online.config(text=f"Error: {error_msg}", foreground="red")
                    log_event("ERROR", f"Error consultando cliente {cli_id}: {error_msg}")
            except Exception as e:
                log_event("ERROR", f"Error consultando cliente: {e}")
                self.label_info_cliente_online.config(text=f"Error: {str(e)}", foreground="red")
        
        thread = threading.Thread(target=_consultar, daemon=True)
        thread.start()
    
    def cargar_catalogo_online(self, pais_id):
        """Cargar catálogo de productos para el país"""
        def _cargar():
            try:
                log_event("API", f"Cargando catálogo online país {pais_id}...")
                response = requests.get(
                    f"{API_BASE_URL}/api/v1/catalogo-online/{pais_id}",
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    self.catalogo_online = response.json()
                    
                    # Limpiar tree
                    for item in self.tree_productos_online.get_children():
                        self.tree_productos_online.delete(item)
                    
                    # Agregar productos
                    if self.catalogo_online:
                        for producto in self.catalogo_online:
                            self.tree_productos_online.insert("", tk.END, values=(
                                producto["pro_cod"],
                                producto["pro_nom"],
                                f"${producto['precio']:.2f}",
                                producto["limite_compra"]
                            ))
                        log_event("SUCCESS", f"Catálogo online cargado: {len(self.catalogo_online)} productos")
                    else:
                        log_event("WARNING", "Catálogo vacío para este país")
                        messagebox.showinfo("Info", "No hay productos disponibles en el catálogo para este país")
                else:
                    error_msg = response.json().get("error", f"Error {response.status_code}")
                    log_event("ERROR", f"Error cargando catálogo: {error_msg}")
                    messagebox.showerror("Error", f"Error cargando catálogo: {error_msg}")
            except Exception as e:
                log_event("ERROR", str(e))
        
        thread = threading.Thread(target=_cargar, daemon=True)
        thread.start()
    
    def iniciar_factura_online(self):
        """Iniciar una nueva factura online"""
        cli_id = self.entry_cliente_online.get().strip()
        if not cli_id:
            messagebox.showwarning("Advertencia", "Ingresa ID de cliente")
            return
        
        def _iniciar():
            try:
                response = requests.post(
                    f"{API_BASE_URL}/api/v1/facturas-online/iniciar",
                    json={"cliente_id": int(cli_id)},
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 201:
                    data = response.json()
                    self.factura_online_actual = data["fact_num"]
                    self.detalles_factura_online = []
                    self.listbox_detalles_online.delete(0, tk.END)
                    messagebox.showinfo("Éxito", f"Factura {self.factura_online_actual} iniciada")
                    log_event("SUCCESS", f"Factura online iniciada: {self.factura_online_actual}")
                else:
                    error = response.json().get("error", "Error desconocido")
                    messagebox.showerror("Error", error)
            except Exception as e:
                log_event("ERROR", str(e))
                messagebox.showerror("Error", str(e))
        
        thread = threading.Thread(target=_iniciar, daemon=True)
        thread.start()
    
    def agregar_detalle_online(self):
        """Agregar un detalle a la factura online"""
        if not self.factura_online_actual:
            messagebox.showwarning("Advertencia", "Primero inicia una factura")
            return
        
        pro_cod = self.entry_prod_cod_online.get().strip()
        cantidad = self.entry_cantidad_online.get().strip()
        
        if not pro_cod or not cantidad:
            messagebox.showwarning("Advertencia", "Ingresa código de producto y cantidad")
            return
        
        try:
            cantidad_int = int(cantidad)
            pro_cod_int = int(pro_cod)
        except ValueError:
            messagebox.showerror("Error", "Cantidad y código deben ser números")
            return
        
        # Validar límite de compra antes de agregar
        producto_encontrado = None
        for producto in self.catalogo_online:
            if producto["pro_cod"] == pro_cod_int:
                producto_encontrado = producto
                break
        
        if not producto_encontrado:
            messagebox.showerror("Error", f"Producto {pro_cod_int} no encontrado en el catálogo")
            return
        
        # Validar límite de compra
        limite_compra = producto_encontrado.get("limite_compra", 0)
        if cantidad_int > limite_compra:
            messagebox.showerror("Error", f"Límite de compra excedido. Máximo permitido: {limite_compra}, Solicitado: {cantidad_int}")
            return
        
        def _agregar():
            try:
                response = requests.post(
                    f"{API_BASE_URL}/api/v1/facturas-online/{self.factura_online_actual}/detalles",
                    json={
                        "producto_cod": pro_cod_int,
                        "cantidad": cantidad_int
                    },
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    data = response.json()
                    detalle_texto = f"Prod {pro_cod_int} x {cantidad_int} - {data.get('mensaje', '')}"
                    self.listbox_detalles_online.insert(tk.END, detalle_texto)
                    self.detalles_factura_online.append({
                        "producto": pro_cod_int,
                        "cantidad": cantidad_int
                    })
                    self.entry_prod_cod_online.delete(0, tk.END)
                    self.entry_cantidad_online.delete(0, tk.END)
                    log_event("SUCCESS", f"Detalle agregado: {detalle_texto}")
                else:
                    error = response.json().get("error", "Error desconocido")
                    messagebox.showerror("Error", error)
                    log_event("ERROR", f"Error agregando detalle: {error}")
            except Exception as e:
                log_event("ERROR", str(e))
                messagebox.showerror("Error", str(e))
        
        thread = threading.Thread(target=_agregar, daemon=True)
        thread.start()
    
    def finalizar_factura_online(self):
        """Finalizar la factura online y mostrar puntos"""
        if not self.factura_online_actual:
            messagebox.showwarning("Advertencia", "No hay factura iniciada")
            return
        
        def _finalizar():
            try:
                response = requests.post(
                    f"{API_BASE_URL}/api/v1/facturas-online/{self.factura_online_actual}/finalizar",
                    timeout=API_TIMEOUT
                )
                
                if response.status_code == 200:
                    data = response.json()
                    total = data.get("total", 0)
                    puntos_gen = data.get("puntos_generados", 0)
                    puntos_tot = data.get("puntos_totales_cliente", 0)
                    venta_gratis = data.get("venta_gratis", False)
                    
                    self.label_total_online.config(text=f"Total: ${total:.2f}")
                    self.label_puntos_online.config(
                        text=f"Puntos generados: {puntos_gen} | Puntos totales cliente: {puntos_tot}"
                    )
                    
                    msg = f"Factura {self.factura_online_actual} finalizada\n"
                    msg += f"Total: ${total:.2f}\n"
                    if venta_gratis:
                        msg += "¡Venta GRATIS aplicada! (Solo envío y recargo)\n"
                    msg += f"Puntos generados: {puntos_gen}\n"
                    msg += f"Puntos totales acumulados: {puntos_tot}"
                    
                    messagebox.showinfo("Éxito", msg)
                    log_event("SUCCESS", f"Factura online finalizada: {self.factura_online_actual}, Total: ${total:.2f}, Puntos: {puntos_gen}")
                else:
                    error = response.json().get("error", "Error desconocido")
                    messagebox.showerror("Error", error)
            except Exception as e:
                log_event("ERROR", str(e))
                messagebox.showerror("Error", str(e))
        
        thread = threading.Thread(target=_finalizar, daemon=True)
        thread.start()
    
    def nueva_venta_online(self):
        """Limpiar y empezar nueva venta online"""
        self.factura_online_actual = None
        self.detalles_factura_online = []
        self.listbox_detalles_online.delete(0, tk.END)
        self.label_total_online.config(text="Total: $0.00")
        self.label_puntos_online.config(text="Puntos generados: 0 | Puntos totales: 0")
        self.entry_prod_cod_online.delete(0, tk.END)
        self.entry_cantidad_online.delete(0, tk.END)
        messagebox.showinfo("Nueva Venta", "Proceso limpiado. Puedes iniciar una nueva venta online.")

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
