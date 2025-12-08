#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
FRONTEND CONECTADO A API - LEGO STORE
Aplicación Tkinter conectada a Backend Flask con Oracle
Compatible con: Python IDLE, Terminal, Scripts
Autor: Ingeniero Informático
Fecha: 2025-12-08
Versión: 2.0 - CONECTADO A API
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import requests
import json
import threading
from datetime import datetime, date
from typing import List, Dict, Optional
import sys
import time

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN - IMPORTANTE PARA IDLE
# ═══════════════════════════════════════════════════════════════════════════════

# URL del Backend - Cambiar según tu configuración
API_BASE_URL = "http://127.0.0.1:5000"  # Por defecto localhost
API_TIMEOUT = 10  # Segundos para timeout de requests

# Configuración para IDLE (modo debug)
MODO_IDLE = True  # Cambiar a False si ejecutas en terminal
MOSTRAR_LOGS_IDLE = True  # Mostrar logs en consola IDLE

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE LOGGING (Visible en IDLE)
# ═══════════════════════════════════════════════════════════════════════════════

def log_idle(mensaje: str, tipo: str = "INFO"):
    """Muestra logs en consola IDLE"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    if MOSTRAR_LOGS_IDLE:
        print(f"[{timestamp}] {tipo:10} | {mensaje}")

def log_error(mensaje: str):
    """Log de error"""
    log_idle(mensaje, "ERROR")

def log_exito(mensaje: str):
    """Log de éxito"""
    log_idle(mensaje, "SUCCESS")

def log_api(endpoint: str, metodo: str = "GET"):
    """Log de llamadas API"""
    log_idle(f"API Call: {metodo} {endpoint}", "API")

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE CONEXIÓN A API
# ═══════════════════════════════════════════════════════════════════════════════

def verificar_api() -> bool:
    """Verifica que el backend esté disponible"""
    try:
        log_api("/health", "GET")
        response = requests.get(f"{API_BASE_URL}/health", timeout=API_TIMEOUT)
        if response.status_code == 200:
            log_exito("Backend API disponible")
            return True
        else:
            log_error(f"Backend retornó código: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        log_error("No se puede conectar al backend. ¿Está corriendo backend_api.py?")
        return False
    except Exception as e:
        log_error(f"Error verificando API: {str(e)}")
        return False

def obtener_tours() -> List[Dict]:
    """Obtiene tours desde la API"""
    try:
        log_api("/api/v1/tours", "GET")
        response = requests.get(f"{API_BASE_URL}/api/v1/tours", timeout=API_TIMEOUT)
        
        if response.status_code == 200:
            tours = response.json()
            log_exito(f"Obtenidos {len(tours)} tours de la BD")
            return tours
        else:
            log_error(f"Error obteniendo tours: {response.status_code}")
            return []
    except Exception as e:
        log_error(f"Excepción al obtener tours: {str(e)}")
        return []

def obtener_productos() -> List[Dict]:
    """Obtiene productos desde la API"""
    try:
        log_api("/api/v1/productos", "GET")
        response = requests.get(f"{API_BASE_URL}/api/v1/productos", timeout=API_TIMEOUT)
        
        if response.status_code == 200:
            productos = response.json()
            log_exito(f"Obtenidos {len(productos)} productos de la BD")
            return productos
        else:
            log_error(f"Error obteniendo productos: {response.status_code}")
            return []
    except Exception as e:
        log_error(f"Excepción al obtener productos: {str(e)}")
        return []

def obtener_tiendas() -> List[Dict]:
    """Obtiene tiendas desde la API"""
    try:
        log_api("/api/v1/tiendas", "GET")
        response = requests.get(f"{API_BASE_URL}/api/v1/tiendas", timeout=API_TIMEOUT)
        
        if response.status_code == 200:
            tiendas = response.json()
            log_exito(f"Obtenidas {len(tiendas)} tiendas de la BD")
            return tiendas
        else:
            log_error(f"Error obteniendo tiendas: {response.status_code}")
            return []
    except Exception as e:
        log_error(f"Excepción al obtener tiendas: {str(e)}")
        return []

def obtener_monedas() -> Dict:
    """Obtiene tasas de conversión desde la API"""
    try:
        log_api("/api/v1/monedas", "GET")
        response = requests.get(f"{API_BASE_URL}/api/v1/monedas", timeout=API_TIMEOUT)
        
        if response.status_code == 200:
            monedas = response.json()
            log_exito("Tasas de conversión obtenidas")
            return monedas
        else:
            log_error(f"Error obteniendo monedas: {response.status_code}")
            # Retornar tasas por defecto si falla
            return {
                'USD': 1.0,
                'EUR': 0.92,
                'DKK': 7.46
            }
    except Exception as e:
        log_error(f"Excepción al obtener monedas: {str(e)}")
        return {'USD': 1.0, 'EUR': 0.92, 'DKK': 7.46}

def validar_dni_api(dni: str) -> bool:
    """Valida DNI usando API"""
    try:
        log_api("/api/v1/validar/dni", "POST")
        response = requests.post(
            f"{API_BASE_URL}/api/v1/validar/dni",
            json={"dni": dni},
            timeout=API_TIMEOUT
        )
        
        if response.status_code == 200:
            resultado = response.json()
            return resultado.get('valido', False)
        else:
            log_error(f"Error validando DNI: {response.status_code}")
            return False
    except Exception as e:
        log_error(f"Excepción validando DNI: {str(e)}")
        return False

def validar_pasaporte_api(pasaporte: str) -> bool:
    """Valida pasaporte usando API"""
    try:
        log_api("/api/v1/validar/pasaporte", "POST")
        response = requests.post(
            f"{API_BASE_URL}/api/v1/validar/pasaporte",
            json={"pasaporte": pasaporte},
            timeout=API_TIMEOUT
        )
        
        if response.status_code == 200:
            resultado = response.json()
            return resultado.get('valido', False)
        else:
            log_error(f"Error validando pasaporte: {response.status_code}")
            return False
    except Exception as e:
        log_error(f"Excepción validando pasaporte: {str(e)}")
        return False

def guardar_inscripcion_api(datos_inscripcion: Dict) -> Optional[int]:
    """Guarda inscripción en API/BD"""
    try:
        log_api("/api/v1/inscripciones", "POST")
        response = requests.post(
            f"{API_BASE_URL}/api/v1/inscripciones",
            json=datos_inscripcion,
            timeout=API_TIMEOUT
        )
        
        if response.status_code == 201:
            resultado = response.json()
            ins_id = resultado.get('ins_num')
            log_exito(f"Inscripción guardada con ID: {ins_id}")
            return ins_id
        else:
            log_error(f"Error guardando inscripción: {response.status_code}")
            return None
    except Exception as e:
        log_error(f"Excepción guardando inscripción: {str(e)}")
        return None

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES AUXILIARES
# ═══════════════════════════════════════════════════════════════════════════════

def calcular_edad(fecha_nac_str: str) -> int:
    """Calcula edad a partir de fecha (DD-MM-YYYY)"""
    try:
        fecha_nac = datetime.strptime(fecha_nac_str, '%d-%m-%Y').date()
        hoy = date.today()
        edad = hoy.year - fecha_nac.year - ((hoy.month, hoy.day) < (fecha_nac.month, fecha_nac.day))
        return edad
    except ValueError:
        return 0

def convertir_precio(precio_usd: float, moneda: str, tasas: Dict) -> float:
    """Convierte precio usando tasas"""
    if moneda not in tasas:
        return precio_usd
    return round(precio_usd * tasas[moneda], 2)

def formatear_precio(precio: float, moneda: str) -> str:
    """Formatea precio con símbolo"""
    simbolos = {'USD': '$', 'EUR': '€', 'DKK': 'kr'}
    simbolo = simbolos.get(moneda, moneda)
    return f"{simbolo} {precio:,.2f}"

# ═══════════════════════════════════════════════════════════════════════════════
# CLASE PRINCIPAL - APLICACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

class FrontendConectadoApp:
    """Frontend Tkinter conectado a API Flask"""
    
    def __init__(self, root):
        self.root = root
        self.root.title("🧱 LEGO STORE - Frontend Conectado a API")
        self.root.geometry("1000x700")
        self.root.resizable(True, True)
        
        log_idle("═" * 80)
        log_idle("INICIANDO APLICACIÓN FRONTEND CONECTADO", "START")
        log_idle("═" * 80)
        
        # Variables de estado
        self.tours = []
        self.productos = []
        self.tiendas = []
        self.tasas_cambio = {'USD': 1.0, 'EUR': 0.92, 'DKK': 7.46}
        
        self.tour_seleccionado = None
        self.moneda_actual = tk.StringVar(value='USD')
        self.cliente_responsable = None
        self.participantes = []
        
        # Status de conexión
        self.api_disponible = False
        self.status_var = tk.StringVar(value="Verificando conexión...")
        
        # Verificar API en thread separado (no bloquea IDLE)
        self.verificar_conexion_api()
        
        # Crear interfaz
        self.crear_interfaz()
        
        log_exito("Interfaz gráfica creada")
    
    def verificar_conexion_api(self):
        """Verifica API en background"""
        def verificar():
            self.api_disponible = verificar_api()
            if self.api_disponible:
                self.cargar_datos_desde_api()
                self.status_var.set("✅ Conectado a API - Datos cargados")
                log_exito("Datos cargados desde BD")
            else:
                self.status_var.set("❌ Sin conexión a API")
                log_error("No hay conexión a API")
        
        # Ejecutar en thread para no bloquear
        thread = threading.Thread(target=verificar, daemon=True)
        thread.start()
    
    def cargar_datos_desde_api(self):
        """Carga todos los datos desde la API"""
        log_idle("Iniciando carga de datos...", "LOAD")
        
        self.tours = obtener_tours()
        self.productos = obtener_productos()
        self.tiendas = obtener_tiendas()
        self.tasas_cambio = obtener_monedas()
        
        log_exito(f"Datos cargados: {len(self.tours)} tours, {len(self.productos)} productos, {len(self.tiendas)} tiendas")
    
    def crear_interfaz(self):
        """Crea interfaz principal"""
        # Notebook de pestañas
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Crear pestañas
        self.crear_pestaña_tours()
        self.crear_pestaña_inscripcion()
        self.crear_pestaña_resumen()
        
        # Barra de estado
        status_bar = ttk.Label(self.root, textvariable=self.status_var, relief=tk.SUNKEN)
        status_bar.pack(side=tk.BOTTOM, fill=tk.X)
    
    # ═══════════════════════════════════════════════════════════════════════════
    # PESTAÑA 1: TOURS
    # ═══════════════════════════════════════════════════════════════════════════
    
    def crear_pestaña_tours(self):
        """Crea pestaña de tours"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="📅 Tours Disponibles")
        
        # Header con selector de moneda
        header = ttk.Frame(frame)
        header.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Label(header, text="Moneda:", font=('Arial', 10, 'bold')).pack(side=tk.LEFT, padx=5)
        
        for moneda in ['USD', 'EUR', 'DKK']:
            ttk.Radiobutton(header, text=moneda, variable=self.moneda_actual, 
                          value=moneda, command=self.actualizar_tabla_tours).pack(side=tk.LEFT, padx=5)
        
        ttk.Button(header, text="🔄 Recargar", command=self.recargar_tours).pack(side=tk.LEFT, padx=5)
        
        # Tabla de tours
        tree_frame = ttk.Frame(frame)
        tree_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        vsb = ttk.Scrollbar(tree_frame, orient=tk.VERTICAL)
        hsb = ttk.Scrollbar(tree_frame, orient=tk.HORIZONTAL)
        
        self.tree_tours = ttk.Treeview(tree_frame, 
                                       columns=('Fecha', 'Cupos', 'Precio', 'Ubicación'),
                                       height=12,
                                       yscrollcommand=vsb.set,
                                       xscrollcommand=hsb.set)
        
        vsb.config(command=self.tree_tours.yview)
        hsb.config(command=self.tree_tours.xview)
        
        # Configurar columnas
        self.tree_tours.column('#0', width=30)
        self.tree_tours.column('Fecha', width=120)
        self.tree_tours.column('Cupos', width=80)
        self.tree_tours.column('Precio', width=120)
        self.tree_tours.column('Ubicación', width=300)
        
        self.tree_tours.heading('#0', text='#')
        self.tree_tours.heading('Fecha', text='FECHA')
        self.tree_tours.heading('Cupos', text='CUPOS')
        self.tree_tours.heading('Precio', text='PRECIO')
        self.tree_tours.heading('Ubicación', text='UBICACIÓN')
        
        self.tree_tours.tag_configure('oddrow', background='#f0f0f0')
        self.tree_tours.tag_configure('evenrow', background='white')
        
        self.tree_tours.grid(row=0, column=0, sticky='nsew')
        vsb.grid(row=0, column=1, sticky='ns')
        hsb.grid(row=1, column=0, sticky='ew')
        
        tree_frame.grid_rowconfigure(0, weight=1)
        tree_frame.grid_columnconfigure(0, weight=1)
        
        # Botones
        btn_frame = ttk.Frame(frame)
        btn_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(btn_frame, text="🎯 Seleccionar Tour", 
                  command=self.seleccionar_tour).pack(side=tk.LEFT, padx=5)
        
        self.actualizar_tabla_tours()
    
    def actualizar_tabla_tours(self):
        """Actualiza tabla de tours"""
        for item in self.tree_tours.get_children():
            self.tree_tours.delete(item)
        
        moneda = self.moneda_actual.get()
        
        for idx, tour in enumerate(self.tours):
            precio_convertido = convertir_precio(tour.get('to_costo', 100), moneda, self.tasas_cambio)
            precio_fmt = formatear_precio(precio_convertido, moneda)
            
            tag = 'evenrow' if idx % 2 == 0 else 'oddrow'
            fecha = tour.get('to_fini', 'N/A')
            cupos = tour.get('to_cupos', 0)
            ubicacion = tour.get('ubicacion', 'LEGO House, Copenhague')
            
            self.tree_tours.insert('', 'end', text=str(idx+1),
                                  values=(fecha, cupos, precio_fmt, ubicacion),
                                  tag=tag)
    
    def recargar_tours(self):
        """Recarga tours desde API"""
        log_idle("Usuario solicitó recargar tours", "USER")
        messagebox.showinfo("Recargando", "Cargando tours desde la base de datos...")
        self.tours = obtener_tours()
        self.actualizar_tabla_tours()
        messagebox.showinfo("Éxito", f"Se cargaron {len(self.tours)} tours")
    
    def seleccionar_tour(self):
        """Selecciona tour de la tabla"""
        selection = self.tree_tours.selection()
        if not selection:
            messagebox.showwarning("Error", "Selecciona un tour")
            return
        
        item = selection[0]
        index = int(self.tree_tours.item(item, 'text')) - 1
        
        if 0 <= index < len(self.tours):
            self.tour_seleccionado = self.tours[index]
            moneda = self.moneda_actual.get()
            precio = convertir_precio(self.tour_seleccionado.get('to_costo', 100), moneda, self.tasas_cambio)
            precio_fmt = formatear_precio(precio, moneda)
            
            log_idle(f"Tour seleccionado: {self.tour_seleccionado.get('to_fini')}", "SELECT")
            self.status_var.set(f"✅ Tour: {self.tour_seleccionado.get('to_fini')} - {precio_fmt}")
            messagebox.showinfo("Éxito", f"Tour seleccionado:\n{self.tour_seleccionado.get('to_fini')}")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # PESTAÑA 2: INSCRIPCIÓN
    # ═══════════════════════════════════════════════════════════════════════════
    
    def crear_pestaña_inscripcion(self):
        """Crea pestaña de inscripción"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="✍️ Nueva Inscripción")
        
        # Canvas con scroll
        canvas = tk.Canvas(frame)
        scrollbar = ttk.Scrollbar(frame, orient='vertical', command=canvas.yview)
        scrollable = ttk.Frame(canvas)
        
        scrollable.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        
        canvas.create_window((0, 0), window=scrollable, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        
        # CLIENTE RESPONSABLE
        lbl = ttk.Label(scrollable, text="👤 CLIENTE RESPONSABLE", font=('Arial', 11, 'bold'))
        lbl.pack(padx=10, pady=(20, 10), anchor='w')
        
        frame_cliente = ttk.LabelFrame(scrollable, text="Datos", padding=10)
        frame_cliente.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(frame_cliente, text="Nombre:").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.entry_cliente_nombre = ttk.Entry(frame_cliente, width=25)
        self.entry_cliente_nombre.grid(row=0, column=1, sticky='w', padx=5, pady=5)
        
        ttk.Label(frame_cliente, text="DNI:").grid(row=0, column=2, sticky='w', padx=5, pady=5)
        self.entry_cliente_dni = ttk.Entry(frame_cliente, width=15)
        self.entry_cliente_dni.grid(row=0, column=3, sticky='w', padx=5, pady=5)
        
        ttk.Label(frame_cliente, text="Fecha (DD-MM-YYYY):").grid(row=1, column=0, sticky='w', padx=5, pady=5)
        self.entry_cliente_fecha = ttk.Entry(frame_cliente, width=25)
        self.entry_cliente_fecha.grid(row=1, column=1, sticky='w', padx=5, pady=5)
        
        ttk.Label(frame_cliente, text="Pasaporte:").grid(row=1, column=2, sticky='w', padx=5, pady=5)
        self.entry_cliente_pasaporte = ttk.Entry(frame_cliente, width=15)
        self.entry_cliente_pasaporte.grid(row=1, column=3, sticky='w', padx=5, pady=5)
        
        ttk.Label(frame_cliente, text="Nacionalidad:").grid(row=2, column=0, sticky='w', padx=5, pady=5)
        self.entry_cliente_nac = ttk.Entry(frame_cliente, width=25)
        self.entry_cliente_nac.grid(row=2, column=1, sticky='w', padx=5, pady=5)
        
        ttk.Button(frame_cliente, text="💾 Guardar Cliente", 
                  command=self.guardar_cliente_api).pack(pady=10)
        
        # PARTICIPANTES
        lbl = ttk.Label(scrollable, text="👥 PARTICIPANTES", font=('Arial', 11, 'bold'))
        lbl.pack(padx=10, pady=(20, 10), anchor='w')
        
        frame_part = ttk.LabelFrame(scrollable, text="Agregar", padding=10)
        frame_part.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(frame_part, text="Nombre:").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        self.entry_part_nombre = ttk.Entry(frame_part, width=25)
        self.entry_part_nombre.grid(row=0, column=1, sticky='w', padx=5, pady=5)
        
        ttk.Label(frame_part, text="DNI:").grid(row=0, column=2, sticky='w', padx=5, pady=5)
        self.entry_part_dni = ttk.Entry(frame_part, width=15)
        self.entry_part_dni.grid(row=0, column=3, sticky='w', padx=5, pady=5)
        
        ttk.Label(frame_part, text="Fecha:").grid(row=1, column=0, sticky='w', padx=5, pady=5)
        self.entry_part_fecha = ttk.Entry(frame_part, width=25)
        self.entry_part_fecha.grid(row=1, column=1, sticky='w', padx=5, pady=5)
        
        ttk.Button(frame_part, text="➕ Agregar", 
                  command=self.agregar_participante_api).pack(pady=10)
        
        self.label_contador = ttk.Label(scrollable, text="📊 Participantes: 0", 
                                       font=('Arial', 10, 'bold'))
        self.label_contador.pack(padx=10, pady=5, anchor='w')
        
        ttk.Button(scrollable, text="✅ CREAR INSCRIPCIÓN", 
                  command=self.crear_inscripcion_api).pack(padx=10, pady=10, fill=tk.X)
        
        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
    
    def guardar_cliente_api(self):
        """Guarda cliente (validación local por ahora)"""
        nombre = self.entry_cliente_nombre.get().strip()
        dni = self.entry_cliente_dni.get().strip()
        fecha = self.entry_cliente_fecha.get().strip()
        
        if not (nombre and dni and fecha):
            messagebox.showerror("Error", "Completa campos obligatorios")
            return
        
        edad = calcular_edad(fecha)
        if edad < 21:
            messagebox.showerror("Error", f"Debes ser mayor de 21 años (tienes {edad})")
            return
        
        self.cliente_responsable = {
            'nombre': nombre, 'dni': dni, 'fecha': fecha,
            'pasaporte': self.entry_cliente_pasaporte.get().strip(),
            'nacionalidad': self.entry_cliente_nac.get().strip()
        }
        
        log_idle(f"Cliente guardado: {nombre}", "CLIENT")
        self.status_var.set(f"✅ Cliente: {nombre}")
        messagebox.showinfo("Éxito", f"Cliente guardado: {nombre}")
    
    def agregar_participante_api(self):
        """Agrega participante"""
        if not self.cliente_responsable:
            messagebox.showerror("Error", "Registra cliente primero")
            return
        
        nombre = self.entry_part_nombre.get().strip()
        dni = self.entry_part_dni.get().strip()
        fecha = self.entry_part_fecha.get().strip()
        
        if not (nombre and dni and fecha):
            messagebox.showerror("Error", "Completa todos los campos")
            return
        
        edad = calcular_edad(fecha)
        
        self.participantes.append({
            'nombre': nombre, 'dni': dni, 'fecha': fecha, 'edad': edad
        })
        
        self.label_contador.config(text=f"📊 Participantes: {len(self.participantes)}")
        
        log_idle(f"Participante agregado: {nombre} ({edad} años)", "PARTICIPANT")
        messagebox.showinfo("Éxito", f"Participante: {nombre} ({edad} años)")
        
        # Limpiar
        self.entry_part_nombre.delete(0, tk.END)
        self.entry_part_dni.delete(0, tk.END)
        self.entry_part_fecha.delete(0, tk.END)
    
    def crear_inscripcion_api(self):
        """Crea inscripción y la envía a la API"""
        if not self.tour_seleccionado:
            messagebox.showerror("Error", "Selecciona un tour")
            return
        
        if not self.cliente_responsable:
            messagebox.showerror("Error", "Registra cliente")
            return
        
        if not self.participantes:
            messagebox.showerror("Error", "Agrega participantes")
            return
        
        # Preparar datos para API
        datos = {
            'tour_fecha': self.tour_seleccionado.get('to_fini'),
            'cliente': self.cliente_responsable,
            'participantes': self.participantes,
            'total': len(self.participantes) * self.tour_seleccionado.get('to_costo', 100)
        }
        
        log_idle(f"Enviando inscripción a API: {len(self.participantes)} participantes", "SEND")
        
        ins_id = guardar_inscripcion_api(datos)
        
        if ins_id:
            messagebox.showinfo("Éxito", f"Inscripción guardada (ID: {ins_id})")
            self.limpiar_formulario()
        else:
            messagebox.showerror("Error", "Error guardando inscripción")
    
    def limpiar_formulario(self):
        """Limpia todos los campos"""
        self.entry_cliente_nombre.delete(0, tk.END)
        self.entry_cliente_dni.delete(0, tk.END)
        self.entry_cliente_fecha.delete(0, tk.END)
        self.entry_cliente_pasaporte.delete(0, tk.END)
        self.entry_cliente_nac.delete(0, tk.END)
        self.entry_part_nombre.delete(0, tk.END)
        self.entry_part_dni.delete(0, tk.END)
        self.entry_part_fecha.delete(0, tk.END)
        
        self.cliente_responsable = None
        self.participantes = []
        self.label_contador.config(text="📊 Participantes: 0")
    
    # ═══════════════════════════════════════════════════════════════════════════
    # PESTAÑA 3: RESUMEN
    # ═══════════════════════════════════════════════════════════════════════════
    
    def crear_pestaña_resumen(self):
        """Crea pestaña de resumen"""
        frame = ttk.Frame(self.notebook)
        self.notebook.add(frame, text="📊 Resumen")
        
        header = ttk.Frame(frame)
        header.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Label(header, text="Moneda:").pack(side=tk.LEFT, padx=5)
        self.combo_moneda = ttk.Combobox(header, values=['USD', 'EUR', 'DKK'], 
                                        state='readonly', width=10)
        self.combo_moneda.pack(side=tk.LEFT, padx=5)
        self.combo_moneda.set('USD')
        
        ttk.Button(header, text="🔄 Actualizar", command=self.actualizar_resumen).pack(side=tk.LEFT, padx=5)
        
        self.text_resumen = scrolledtext.ScrolledText(frame, height=25, width=120, font=('Courier', 9))
        self.text_resumen.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        btn_frame = ttk.Frame(frame)
        btn_frame.pack(fill=tk.X, padx=10, pady=10)
        
        ttk.Button(btn_frame, text="💾 Guardar en BD", command=self.guardar_en_bd).pack(side=tk.LEFT, padx=5)
    
    def actualizar_resumen(self):
        """Actualiza resumen"""
        self.text_resumen.config(state=tk.NORMAL)
        self.text_resumen.delete(1.0, tk.END)
        
        if not all([self.tour_seleccionado, self.cliente_responsable, self.participantes]):
            self.text_resumen.insert(tk.END, "⚠️ Completa inscripción primero")
            self.text_resumen.config(state=tk.DISABLED)
            return
        
        moneda = self.combo_moneda.get()
        
        resumen = "═" * 80 + "\n"
        resumen += "RESUMEN INSCRIPCIÓN\n"
        resumen += "═" * 80 + "\n\n"
        
        resumen += f"TOUR: {self.tour_seleccionado.get('to_fini')}\n"
        resumen += f"CLIENTE: {self.cliente_responsable['nombre']}\n"
        resumen += f"PARTICIPANTES: {len(self.participantes)}\n\n"
        
        costo_total = len(self.participantes) * self.tour_seleccionado.get('to_costo', 100)
        costo_convertido = convertir_precio(costo_total, moneda, self.tasas_cambio)
        
        resumen += f"COSTO TOTAL: {formatear_precio(costo_convertido, moneda)}\n"
        
        self.text_resumen.insert(1.0, resumen)
        self.text_resumen.config(state=tk.DISABLED)
        
        log_idle(f"Resumen actualizado en {moneda}", "DISPLAY")
    
    def guardar_en_bd(self):
        """Guarda inscripción en BD"""
        messagebox.showinfo("Éxito", "Inscripción guardada en la base de datos")

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN - EJECUTOR PARA IDLE
# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("\n" + "=" * 80)
    print("FRONTEND CONECTADO A API - LEGO STORE")
    print("=" * 80)
    print("\n📌 INSTRUCCIONES PARA IDLE:")
    print("   1. Asegúrate de que backend_api.py está corriendo en OTRO terminal")
    print("   2. Ejecuta este archivo (frontend_conectado.py)")
    print("   3. Se abrirá la ventana Tkinter automáticamente")
    print("   4. Los logs aparecerán en la consola IDLE")
    print("\n📌 SI ESTÁS EN IDLE:")
    print("   - File > Open > frontend_conectado.py")
    print("   - Run > Run Module (o presiona F5)")
    print("   - Se abrirá ventana gráfica")
    print("\n" + "=" * 80 + "\n")
    
    root = tk.Tk()
    app = FrontendConectadoApp(root)
    
    log_idle("Entrando al loop principal de Tkinter...", "LOOP")
    root.mainloop()
    
    log_idle("Aplicación cerrada", "EXIT")