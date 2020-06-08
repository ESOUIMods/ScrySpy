local strings = {
    mod_title                           = "ScrySpy",
    map_pin_texture_text                = "Apparence du marqueur sur la carte",
    map_pin_texture_desc                = "Permet de choisir une ic�ne pour le marqueur sur la carte",
    digsite_texture_text                = "Apparence pour le site de fouille",
    digsite_texture_desc                = "Permet de choisir une ic�ne 3D pour le site de fouille dans le paysage",
    pin_size                            = "Taille du marqueur sur la carte",
    pin_size_desc                       = "Choisir la taille du marqueur sur la carte",
    pin_layer                           = "Priorit� du marqueur",
    pin_layer_desc                      = "Choisir une priorit� pour le marqueur afin qu'il soit visible au-dessus d'autres marqueurs pr�sents au m�me endroit.",
    show_digsites_on_compas             = "Afficher les sites de fouille sur le compas",
    show_digsites_on_compas_desc        = "Permet d'afficher d'afficher ou cacher l'ic�ne des sites de fouille sur le compas",
    compass_max_dist                    = "Distance max pour afficher le marqueur",
    compass_max_dist_desc               = "Permet de d�finir la distance maximale pour faire apparaitre les ic�nes sur le compas.",
    spike_pincolor                      = "Couleur de la partie basse du marqueur 3D",
    spike_pincolor_desc                 = "Permet de choisir la couleur de la partie basse du marqueur 3D.",
}

for stringId, stringValue in pairs(strings) do
    SafeAddString(_G[stringId], stringValue, 1)
end
