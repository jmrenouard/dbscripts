     (select E.expedition_id Id, E.date_creation 'Date Creation', E.valide Valide, E.valide_le 'Date validation', EE.libelle Expediteur, ET.nom Transporteur, E.destinataire_nom Destinataire, E.destinataire_cp CP, E.destinataire_ville Ville, EP.nom Pays, E.demat Demat, case when demat_fichier is null then '' else 'X' end Fichier, E.destinataire_contact Contact, EI.nom Incoterms, E.annule Annule, E.annule_le 'Date annulation'
                 (select group_concat(EB.bl_reference) from expedition_bl EB where EB.expedition_id = E.expedition_id) BL
                 (select group_concat(EB.bl_reference_pmi) from expedition_bl EB where EB.expedition_id = E.expedition_id) 'Ref PMI'
                 (select count(*) from expedition_colis EC where EC.expedition_id = E.expedition_id" + (RBVisu01.Checked ? " and E.annule = 0" : "") ) 'Nb', 'Colis' Mode
                 (select group_concat(EC.reference_colis) from expedition_colis EC where EC.expedition_id = E.expedition_id" + (RBVisu01.Checked ? " and E.annule = 0" : "") ) Colis
                 (select sum(EC.poids) from expedition_colis EC where EC.expedition_id = E.expedition_id" + (RBVisu01.Checked ? " and E.annule = 0" : "") ) Poids
                 (select sum(round(ifnull((EC.hauteur / 1000.00) * (EC.largeur / 1000.00) * (EC.longueur / 1000.00), 0), 3)) from expedition_colis EC where EC.expedition_id = E.expedition_id" + (RBVisu01.Checked ? " and E.annule = 0" : "") ) Volume
                 E.matricule Matricule
                 from expedition E left join expedition_pays EP on E.destinataire_pays_id = EP.pays_id
                 left join expedition_expediteur EE on E.expediteur_id = EE.expediteur_id
                 left join expedition_transporteur ET on E.transporteur_id = ET.transporteur_id
                 left join expedition_incoterms EI on E.incoterms_id = EI.incoterms_id          
                 where E.valide_le between '" + DteDeb.Value.ToString("yyyy-MM-dd HH:mm") ' and '" + DteFin.Value.ToString("yyyy-MM-dd HH:mm") '          
                 and E.valide = 0
                 and E.annule = 0

                 and E.expediteur_id = " + CboExpediteur.SelectedValue.ToString();
                 and E.transporteur_id = " + CboTransporteur.SelectedValue.ToString();
                 and E.destinataire_pays_id = " + CboDestinataire_Pays.SelectedValue.ToString();
                 and E.destinataire_nom like '" + TxtDestinataire.Text.Replace("'", "''") '
                 and E.destinataire_cp like '" + TxtCP.Text.Replace("'", "''") '
                 and E.destinataire_ville like '" + TxtVille.Text.Replace("'", "''") '
                 and exists (select * from expedition_colis EC where EC.expedition_id = E.expedition_id and EC.reference_colis like '" + TxtColis.Text.Replace("'", "''") ')
                 and exists (select * from expedition_bl EB where EB.expedition_id = E.expedition_id and EB.bl_reference like '" + TxtBL.Text.Replace("'", "''") ')";
                 and exists (select * from expedition_bl EB where EB.expedition_id = E.expedition_id and EB.bl_reference_pmi like '" + TxtRefPMI.Text.Replace("'", "''") ')
                
                 and (select count(*) from expedition_colis C where C.expedition_id = E.expedition_id and C.colis_no =1) > 0 order by 1 desc)

            
            
             UNION 
                select E.expedition_id Id, E.date_creation 'Date Creation', E.valide Valide, E.valide_le 'Date validation', EE.libelle Expediteur, ET.nom Transporteur,
                E.destinataire_nom Destinataire, E.destinataire_cp CP, E.destinataire_ville Ville, EP.nom Pays, E.demat Demat, case when demat_fichier is null
                 then '' else 'X' end Fichier, E.destinataire_contact Contact, EI.nom Incoterms, E.annule Annule, E.annule_le 'Date annulation'  ,
                 (select group_concat(EB.bl_reference) from expedition_bl EB where EB.expedition_id = E.expedition_id) BL , 
                 (select group_concat(EB.bl_reference_pmi) from expedition_bl EB where EB.expedition_id = E.expedition_id) 'Ref PMI' , 
                 (select count(*) from expedition_palette PP where PP.expedition_id = E.expedition_id) 'Nb', 'Palette' Mode,
                 (select sum(PP.nb_colis) from expedition_palette PP where PP.expedition_id = E.expedition_id) Colis , 
                 (select sum(PP.poids) from expedition_palette PP where PP.expedition_id = E.expedition_id) Poids , 
                 (select sum(round(ifnull((PP.hauteur / 1000.00) * (PP.largeur / 1000.00) * (PP.longueur / 1000.00), 0), 3)) from expedition_palette PP where PP.expedition_id = E.expedition_id) Volume , 
                 E.matricule Matricule
                 from expedition E
                 left join expedition_expediteur EE on E.expediteur_id = EE.expediteur_id
                 left join expedition_transporteur ET on E.transporteur_id = ET.transporteur_id
                 left join expedition_pays EP on E.destinataire_pays_id = EP.pays_id
                 left join expedition_incoterms EI on E.incoterms_id = EI.incoterms_id

             where E.valide_le between '" + DteDeb.Value.ToString("yyyy-MM-dd HH:mm") ' and '" + DteFin.Value.ToString("yyyy-MM-dd HH:mm") '          
                 and E.valide = 0
                 and E.annule = 0

                 and E.expediteur_id = " + CboExpediteur.SelectedValue.ToString();
                 and E.transporteur_id = " + CboTransporteur.SelectedValue.ToString();
                 and E.destinataire_pays_id = " + CboDestinataire_Pays.SelectedValue.ToString();
                 and E.destinataire_nom like '" + TxtDestinataire.Text.Replace("'", "''") '
                 and E.destinataire_cp like '" + TxtCP.Text.Replace("'", "''") '
                 and E.destinataire_ville like '" + TxtVille.Text.Replace("'", "''") '
                 and exists (select * from expedition_colis EC where EC.expedition_id = E.expedition_id and EC.reference_colis like '" + TxtColis.Text.Replace("'", "''") ')
                 and exists (select * from expedition_bl EB where EB.expedition_id = E.expedition_id and EB.bl_reference like '" + TxtBL.Text.Replace("'", "''") ')";
                 and exists (select * from expedition_bl EB where EB.expedition_id = E.expedition_id and EB.bl_reference_pmi like '" + TxtRefPMI.Text.Replace("'", "''") ')
           
             and exists (select * from expedition_palette P where P.expedition_id = E.expedition_id and P.palette_no = 1) order by 1 desc)