from pathlib import Path
import xml.etree.ElementTree as ET

mxfile = ET.Element('mxfile', {
    'host': 'app.diagrams.net',
    'modified': '2026-10-09T15:00:00.000Z',
    'agent': 'AtlArt',
    'version': '21.0.0',
    'type': 'device',
})
diagram = ET.SubElement(mxfile, 'diagram', {'id': 'sequence-publication', 'name': 'Publication article'})
model = ET.SubElement(diagram, 'mxGraphModel', {
    'dx': '1600', 'dy': '1450', 'grid': '1', 'gridSize': '10', 'guides': '1',
    'tooltips': '1', 'connect': '1', 'arrows': '1', 'fold': '1', 'page': '1',
    'pageScale': '1', 'pageWidth': '1600', 'pageHeight': '1450', 'math': '0', 'shadow': '0',
})
root = ET.SubElement(model, 'root')
ET.SubElement(root, 'mxCell', {'id': '0'})
ET.SubElement(root, 'mxCell', {'id': '1', 'parent': '0'})

def vertex(identifier, value, x, y, w, h, style):
    c = ET.SubElement(root, 'mxCell', {
        'id': identifier, 'value': value, 'style': style,
        'vertex': '1', 'parent': '1',
    })
    ET.SubElement(c, 'mxGeometry', {
        'x': str(x), 'y': str(y), 'width': str(w), 'height': str(h), 'as': 'geometry',
    })

def edge(identifier, value, x1, y1, x2, y2, style):
    c = ET.SubElement(root, 'mxCell', {
        'id': identifier, 'value': value, 'style': style,
        'edge': '1', 'parent': '1',
    })
    g = ET.SubElement(c, 'mxGeometry', {'relative': '1', 'as': 'geometry'})
    ET.SubElement(g, 'mxPoint', {'x': str(x1), 'y': str(y1), 'as': 'sourcePoint'})
    ET.SubElement(g, 'mxPoint', {'x': str(x2), 'y': str(y2), 'as': 'targetPoint'})

font = 'fontFamily=Arial;fontSize=13;html=1;whiteSpace=wrap;'
vertex('title', "Publication d’un article artisanal — séquence Flutter / Laravel", 180, 18, 1240, 36,
       f'text;align=center;verticalAlign=middle;strokeColor=none;fillColor=none;fontStyle=1;fontSize=21;{font}')
vertex('subtitle', 'Le dépôt crée une demande de modération ; il ne rend pas immédiatement l’article public.',
       240, 48, 1120, 24,
       f'text;align=center;verticalAlign=middle;strokeColor=none;fillColor=none;fontColor=#526173;fontSize=13;{font}')

participants = [
    ('artisan', 'Artisan', 90, 140, 140, '#dae8fc', '#6c8ebf'),
    ('ui', 'Application Flutter\n(Formulaire)', 370, 370, 190, '#fff2cc', '#d6b656'),
    ('service', 'Service Flutter\n(OeuvreApi)', 640, 640, 190, '#fff2cc', '#d6b656'),
    ('api', 'API Laravel\n(Oeuvre / Image)', 920, 920, 200, '#d5e8d4', '#82b366'),
    ('storage', 'Stockage fichiers\n(disque public)', 1190, 1190, 200, '#f8cecc', '#b85450'),
    ('db', 'Base MariaDB', 1460, 1460, 140, '#e1d5e7', '#9673a6'),
]
centers = {}
for pid, label, cx, _, width, fill, stroke in participants:
    centers[pid] = cx
    vertex(f'head-{pid}', label, cx - width // 2, 90, width, 58,
           f'rounded=1;arcSize=8;whiteSpace=wrap;html=1;align=center;verticalAlign=middle;'
           f'fillColor={fill};strokeColor={stroke};fontSize=14;fontStyle=1;{font}')

# Lifelines.
life_end = 1400
for pid, _, cx, _, _, _, stroke in participants:
    edge(f'life-{pid}', '', cx, 148, cx, life_end,
         f'endArrow=none;startArrow=none;dashed=1;dashPattern=2 5;strokeWidth=1.4;strokeColor={stroke};html=1;')

# Frames are intentionally subtle so the messages remain dominant.
vertex('loop', 'loop  Pour chaque photo', 590, 500, 930, 260,
       'shape=umlFrame;whiteSpace=wrap;html=1;boundedLbl=1;fillColor=none;strokeColor=#8190a3;'
       'fontStyle=1;fontSize=13;labelBackgroundColor=#ffffff;')
vertex('alt', 'alt  Résultat de la publication', 55, 790, 1470, 590,
       'shape=umlFrame;whiteSpace=wrap;html=1;boundedLbl=1;fillColor=none;strokeColor=#8190a3;'
       'fontStyle=1;fontSize=13;labelBackgroundColor=#ffffff;')
edge('alt-separator', '', 56, 1075, 1524, 1075,
     'endArrow=none;startArrow=none;dashed=1;strokeColor=#8190a3;strokeWidth=1;')
vertex('success-label', '[Succès : photos envoyées et demande soumise]', 615, 805, 480, 25,
       f'text;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;fontStyle=1;fontColor=#287a45;{font}')
vertex('failure-label', '[Échec après création de l’article : nettoyage]', 615, 1085, 480, 25,
       f'text;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;fontStyle=1;fontColor=#b33a35;{font}')

call = 'endArrow=block;endFill=1;strokeColor=#26384a;strokeWidth=1.4;html=1;align=center;verticalAlign=bottom;'
ret = 'endArrow=open;endFill=0;dashed=1;dashPattern=5 4;strokeColor=#526173;strokeWidth=1.2;html=1;align=center;verticalAlign=bottom;'

messages = [
    ('m1', '1. Remplir les informations et ajouter les photos', 'artisan', 'ui', 180, call),
    ('m2', '2. Soumettre l’article', 'artisan', 'ui', 220, call),
    ('m3', '3. publishArtisanArticle(article, photos)', 'ui', 'service', 260, call),
    ('m4', '4. Vérifier le jeton et au moins une photo', 'service', 'service', 300, call),
    ('m5', '5. POST /api/oeuvres (données de l’article)', 'service', 'api', 350, call),
    ('m6', '6. Créer le brouillon (valeurs initiales)', 'api', 'db', 395, call),
    ('m7', '7. Retourner l’œuvre et son UUID', 'db', 'api', 435, ret),
    ('m8', '8. Réponse 201 avec l’identifiant', 'api', 'service', 475, ret),
    ('m9', '9. POST /api/images (multipart)', 'service', 'api', 535, call),
    ('m10', '10. Écrire le fichier', 'api', 'storage', 575, call),
    ('m11', '11. Retourner le chemin du fichier', 'storage', 'api', 615, ret),
    ('m12', '12. Enregistrer les métadonnées de l’image', 'api', 'db', 655, call),
    ('m13', '13. Confirmer l’insertion', 'db', 'api', 695, ret),
    ('m14', '14. Réponse 201 avec image_url', 'api', 'service', 735, ret),
    ('m15', '15. PATCH /api/oeuvres/{id} : brouillon=false, étape=4', 'service', 'api', 850, call),
    ('m16', '16. Mettre à jour et créer la demande de modération', 'api', 'db', 890, call),
    ('m17', '17. Statut en attente de vérification', 'db', 'api', 930, ret),
    ('m18', '18. Réponse 200 avec l’œuvre mise à jour', 'api', 'service', 970, ret),
    ('m19', '19. Retourner l’identifiant à l’écran', 'service', 'ui', 1010, ret),
    ('m20', '20. Afficher la confirmation de soumission', 'ui', 'artisan', 1050, ret),
    ('m21', '21. DELETE /api/oeuvres/{id} (nettoyage)', 'service', 'api', 1130, call),
    ('m22', '22. Supprimer les fichiers associés', 'api', 'storage', 1170, call),
    ('m23', '23. Supprimer les métadonnées et le brouillon', 'api', 'db', 1210, call),
    ('m24', '24. Confirmer le nettoyage', 'db', 'api', 1250, ret),
    ('m25', '25. Réponse 204', 'api', 'service', 1290, ret),
    ('m26', '26. Renvoyer l’erreur à l’écran', 'service', 'ui', 1330, ret),
    ('m27', '27. Afficher l’échec et proposer de réessayer', 'ui', 'artisan', 1370, ret),
]
for mid, label, src, dst, y, style in messages:
    x1, x2 = centers[src], centers[dst]
    if src == dst:
        # Draw a small right-side self-call loop without crossing the lifeline.
        edge(mid, label, x1, y, x1 + 100, y + 15,
             'edgeStyle=orthogonalEdgeStyle;rounded=1;endArrow=block;endFill=1;'
             'strokeColor=#26384a;strokeWidth=1.3;html=1;fontSize=12;')
    else:
        edge(mid, label, x1, y, x2, y, style + 'fontSize=12;labelBackgroundColor=#ffffff;')

vertex('footnote', 'Si le POST initial échoue, aucun article n’a été créé à nettoyer. La visibilité publique intervient après modération.',
       250, 1410, 1100, 24,
       f'text;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontColor=#526173;fontSize=12;{font}')

Path('docs').mkdir(exist_ok=True)
ET.indent(mxfile, space='  ')
ET.ElementTree(mxfile).write('docs/sequence_publication_atlart.drawio', encoding='utf-8', xml_declaration=True)
