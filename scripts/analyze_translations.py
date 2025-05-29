#!/usr/bin/env python3
"""
Análisis de traducciones para Hero Budget
Analiza todos los archivos de traducción en assets/l10n para encontrar claves faltantes
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, Set, List, Tuple

def load_json_file(file_path: str) -> Dict:
    """Carga un archivo JSON y retorna su contenido"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        return {}

def get_all_keys(data: Dict, prefix: str = "") -> Set[str]:
    """Extrae todas las claves de un diccionario JSON anidado"""
    keys = set()
    for key, value in data.items():
        full_key = f"{prefix}{key}" if prefix else key
        keys.add(full_key)
        if isinstance(value, dict):
            keys.update(get_all_keys(value, f"{full_key}."))
    return keys

def analyze_translations():
    """Analiza todos los archivos de traducción y encuentra claves faltantes"""
    
    # Directorio de traducciones
    l10n_dir = Path("assets/l10n")
    
    if not l10n_dir.exists():
        print(f"❌ Directory {l10n_dir} not found!")
        return
    
    # Obtener todos los archivos JSON
    json_files = list(l10n_dir.glob("*.json"))
    
    if not json_files:
        print("❌ No JSON files found in assets/l10n!")
        return
    
    print(f"🔍 Found {len(json_files)} translation files")
    
    # Cargar archivo de referencia (inglés)
    reference_file = l10n_dir / "en.json"
    if not reference_file.exists():
        print("❌ Reference file en.json not found!")
        return
    
    reference_data = load_json_file(str(reference_file))
    reference_keys = get_all_keys(reference_data)
    
    print(f"📋 Reference file (en.json) has {len(reference_keys)} keys")
    print("="*60)
    
    # Analizar cada archivo
    missing_translations = {}
    file_stats = {}
    
    for json_file in sorted(json_files):
        lang_code = json_file.stem
        print(f"\n🌍 Analyzing {lang_code}.json...")
        
        # Cargar datos del idioma
        lang_data = load_json_file(str(json_file))
        lang_keys = get_all_keys(lang_data)
        
        # Encontrar claves faltantes
        missing_keys = reference_keys - lang_keys
        extra_keys = lang_keys - reference_keys
        
        # Estadísticas
        coverage = ((len(lang_keys) - len(extra_keys)) / len(reference_keys)) * 100
        
        file_stats[lang_code] = {
            'total_keys': len(lang_keys),
            'missing_keys': len(missing_keys),
            'extra_keys': len(extra_keys),
            'coverage': coverage
        }
        
        if missing_keys:
            missing_translations[lang_code] = sorted(list(missing_keys))
        
        # Mostrar estadísticas
        print(f"   📊 Total keys: {len(lang_keys)}")
        print(f"   ❌ Missing keys: {len(missing_keys)}")
        print(f"   ➕ Extra keys: {len(extra_keys)}")
        print(f"   📈 Coverage: {coverage:.1f}%")
        
        if extra_keys:
            print(f"   🔍 Extra keys found: {', '.join(sorted(extra_keys)[:5])}")
            if len(extra_keys) > 5:
                print(f"       ... and {len(extra_keys) - 5} more")
    
    # Resumen general
    print("\n" + "="*60)
    print("📊 SUMMARY REPORT")
    print("="*60)
    
    # Ordenar por cobertura
    sorted_langs = sorted(file_stats.items(), key=lambda x: x[1]['coverage'], reverse=True)
    
    print(f"{'Language':<12} {'Coverage':<10} {'Missing':<8} {'Total':<8}")
    print("-" * 40)
    
    for lang, stats in sorted_langs:
        print(f"{lang:<12} {stats['coverage']:>6.1f}% {stats['missing_keys']:>6} {stats['total_keys']:>6}")
    
    # Idiomas que necesitan trabajo
    print(f"\n🚨 Languages needing attention (< 95% coverage):")
    needs_work = [(lang, stats) for lang, stats in sorted_langs if stats['coverage'] < 95]
    
    if needs_work:
        for lang, stats in needs_work:
            print(f"   • {lang}: {stats['coverage']:.1f}% coverage, {stats['missing_keys']} missing keys")
    else:
        print("   ✅ All languages have good coverage!")
    
    # Guardar reporte detallado
    report = {
        'reference_keys_count': len(reference_keys),
        'total_files': len(json_files),
        'file_stats': file_stats,
        'missing_translations': missing_translations,
        'reference_keys': sorted(list(reference_keys))
    }
    
    report_file = "scripts/translation_analysis_report.json"
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Detailed report saved to: {report_file}")
    
    return missing_translations, file_stats

if __name__ == "__main__":
    print("🔄 Starting translation analysis...")
    missing_translations, file_stats = analyze_translations()
    
    if missing_translations:
        print(f"\n🎯 Found missing translations in {len(missing_translations)} languages")
    else:
        print("\n✅ All translations are complete!") 