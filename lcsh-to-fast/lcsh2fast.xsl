<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:srw="http://www.loc.gov/zing/srw/"
    exclude-result-prefixes="srw"
    version="2.0">
    
    <xsl:output method="xml" indent="yes"/>
    <xsl:strip-space elements="*"/>    
        
    <xsl:template match="/">
        <xsl:result-document href="{substring-before(base-uri(),'.xml')}_fast.xml">
            <xsl:choose>
                <!-- If root element is mods:modsCollection -->
                <xsl:when test="mods:modsCollection">
                    <xsl:for-each select="mods:modsCollection">
                        <mods:modsCollection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                            xmlns:mods="http://www.loc.gov/mods/v3"
                            xmlns:xs="http://www.w3.org/2001/XMLSchema"
                            xmlns:local="http://www.loc.org/namespace"
                            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
                            <xsl:for-each select="mods:mods">
                                <mods:mods version="3.7">
                                    <xsl:call-template name="sort_and_dedup_mods">
                                        <xsl:with-param name="output_raw">
                                            <xsl:apply-templates select="*" mode="all_copy"/>
                                            <xsl:call-template name="mods_processing"/>
                                        </xsl:with-param>
                                    </xsl:call-template>  
                                </mods:mods>
                            </xsl:for-each>
                        </mods:modsCollection>
                    </xsl:for-each>
                </xsl:when>
                <!-- If root element is mods:mods -->
                <xsl:when test="mods:mods">
                    <xsl:for-each select="mods:mods">
                        <mods:mods xmlns:mods="http://www.loc.gov/mods/v3" version="3.7">
                            <xsl:call-template name="sort_and_dedup_mods">
                                <xsl:with-param name="output_raw">
                                    <xsl:apply-templates select="*" mode="all_copy"/>
                                    <xsl:call-template name="mods_processing"/>
                                </xsl:with-param>
                            </xsl:call-template>
                        </mods:mods>
                    </xsl:for-each>
                </xsl:when>
                <!-- If root element is marc:collection -->
                <xsl:when test="marc:collection">
                    <marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">
                        <xsl:for-each select="//marc:record">
                            <marc:record>
                                <xsl:call-template name="sort_and_dedup_marc">
                                    <xsl:with-param name="output_raw">
                                        <xsl:apply-templates select="*" mode="all_copy"/>
                                        <xsl:apply-templates select="self::marc:record" mode="fast"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </marc:record>
                        </xsl:for-each>
                    </marc:collection>
                </xsl:when>
                <!-- If root element is marc:record -->
                <xsl:when test="marc:record">
                    <marc:record xmlns:marc="http://www.loc.gov/MARC21/slim">
                        <xsl:call-template name="sort_and_dedup_marc">
                            <xsl:with-param name="output_raw">
                                <xsl:apply-templates select="marc:record/*" mode="all_copy"/>
                                <xsl:apply-templates select="marc:record" mode="fast"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </marc:record>
                </xsl:when>
            </xsl:choose>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="marc:record" mode="fast">
        <!-- MARC 600 -->
        <xsl:for-each select="marc:datafield[@tag=600][@ind2=0]">
            <!-- $v $ x $y $z -->
            <xsl:call-template name="subdivision_x_processing"/>
            <xsl:call-template name="subdivision_vy_processing"/>
            <xsl:call-template name="subdivision_y_processing"/>
            <xsl:call-template name="subdivision_z_processing"/>
            <!-- Name-title entry -->
            <xsl:if test="marc:subfield[@code='t']">
                <xsl:variable name="subjectString">
                    <xsl:variable name="subjectString_raw">
                        <!--<xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q' or @code='t' or @code='l' or @code='k']">
                            <xsl:value-of select="text()"/>
                            <xsl:text> </xsl:text>
                        </xsl:for-each>-->
                        <xsl:for-each select="marc:subfield[@code='t']">
                            <xsl:value-of select="replace(text(),'\.$','')"/>
                            <xsl:text> </xsl:text>
                        </xsl:for-each>
                        <xsl:variable name="name-qualifier">
                            <xsl:text>(</xsl:text>
                            <xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c']">
                                <xsl:value-of select="text()"/>
                                <xsl:text> </xsl:text>
                            </xsl:for-each>
                            <xsl:text>)</xsl:text>
                        </xsl:variable>
                        <xsl:value-of select="replace($name-qualifier,', \)',')')"/>
                    </xsl:variable>
                    <xsl:value-of select="replace(replace(normalize-space($subjectString_raw),'\.\.','.'),'\.$','')"/>
                </xsl:variable>
                <xsl:for-each select="$subjectString">
                    <xsl:call-template name="lc2fast_subfield">
                        <xsl:with-param name="subfield_code">t</xsl:with-param>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>
            <!-- Personal Name-only entry -->
            <xsl:variable name="subjectString">
                <xsl:variable name="subjectString_raw">
                    <xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q']">
                        <xsl:value-of select="text()"/>
                        <xsl:text> </xsl:text>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:value-of select="replace(replace(normalize-space($subjectString_raw),'\.\.','.'),'\.$','')"/>
            </xsl:variable>
            <xsl:for-each select="$subjectString">
                <xsl:call-template name="lc2fast_subfield">
                    <xsl:with-param name="subfield_code">p</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
        <!-- MARC 610 -->
        <xsl:for-each select="marc:datafield[@tag=610][@ind2=0]">
            <xsl:call-template name="subdivision_x_processing"/>
            <xsl:call-template name="subdivision_vy_processing"/>
            <xsl:call-template name="subdivision_y_processing"/>
            <xsl:call-template name="subdivision_z_processing"/>
            <xsl:call-template name="conf-corp_name_processing"/>
            <!-- Name-title entry -->
            <xsl:if test="marc:subfield[@code='t']">
                <xsl:variable name="subjectString">
                    <xsl:variable name="subjectString_raw">
                        <xsl:for-each select="marc:subfield[@code='t']">
                            <xsl:value-of select="replace(text(),'\.$','')"/>
                            <xsl:text> </xsl:text>
                        </xsl:for-each>
                        <xsl:variable name="name-qualifier">
                            <xsl:text>(</xsl:text>
                            <xsl:for-each select="marc:subfield[@code='a' or @code='b']">
                                <xsl:value-of select="text()"/>
                                <xsl:text> </xsl:text>
                            </xsl:for-each>
                            <xsl:text>)</xsl:text>
                        </xsl:variable>
                        <xsl:value-of select="replace($name-qualifier,', \)',')')"/>
                    </xsl:variable>
                    <xsl:value-of select="replace(replace(normalize-space($subjectString_raw),'\.\.','.'),'\.$','')"/>
                </xsl:variable>
                <xsl:for-each select="$subjectString">
                    <xsl:call-template name="lc2fast_subfield">
                        <xsl:with-param name="subfield_code">t</xsl:with-param>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each>
        <!-- MARC 611 -->
        <xsl:for-each select="marc:datafield[@tag=611][@ind2=0]">
            <xsl:call-template name="subdivision_x_processing"/>
            <xsl:call-template name="subdivision_vy_processing"/>
            <xsl:call-template name="subdivision_y_processing"/>
            <xsl:call-template name="subdivision_z_processing"/>
            <xsl:call-template name="conf-corp_name_processing"/>
        </xsl:for-each>
        <!-- MARC 630 -->
        <xsl:for-each select="marc:subfield[@tag=630][@ind2=0]">
            <xsl:variable name="subjectString">
                <xsl:variable name="subjectString_raw">
                    <xsl:for-each select="marc:subfield[@code='a' or @code='p' or @code='k' or @code='l']">
                        <xsl:value-of select="text()"/>
                        <xsl:text> </xsl:text>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:value-of select="replace(replace(normalize-space($subjectString_raw),'\.\.','.'),'\.$','')"/>
            </xsl:variable>
            <xsl:for-each select="$subjectString">
                <xsl:call-template name="lc2fast_subfield">
                    <xsl:with-param name="subfield_code">t</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
        <!-- MARC 650 -->
        <xsl:for-each select="marc:datafield[@tag=650][@ind2=0]">
            <xsl:variable name="topical_fast">
                <xsl:for-each select="marc:subfield[@code='a']">
                    <!-- Subfield $a & $x -->
                    <xsl:variable name="topical_subject">
                        <xsl:value-of select="text(),following-sibling::marc:subfield[@code='x']" separator="--"/>
                    </xsl:variable>
                    <xsl:for-each select="replace($topical_subject,'\.$','')">
                        <xsl:call-template name="lc2fast_subfield">
                            <xsl:with-param name="subfield_code">x</xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:variable>
            <xsl:choose>
                <!-- If FAST found for concatentated topical heading -->
                <xsl:when test="string-length($topical_fast)!=0">
                    <xsl:copy-of select="$topical_fast"/>
                    <xsl:call-template name="subdivision_vy_processing"/>
                    <xsl:call-template name="subdivision_y_processing"/>
                    <xsl:call-template name="subdivision_z_processing"/>
                </xsl:when>
                <!-- If no FAST for concatentated topical heading -->
                <xsl:otherwise>
                    <!-- Subfield $a only -->
                    <xsl:for-each select="marc:subfield[@code='a']">
                        <xsl:call-template name="lc2fast_subfield">
                            <xsl:with-param name="subfield_code">x</xsl:with-param>
                        </xsl:call-template>
                    </xsl:for-each>
                    <!-- Non-subfield $a -->
                    <xsl:call-template name="subdivision_x_processing"/>
                    <xsl:call-template name="subdivision_vy_processing"/>
                    <xsl:call-template name="subdivision_y_processing"/>
                    <xsl:call-template name="subdivision_z_processing"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- All subfields -->
            <xsl:variable name="subjectString">
                <xsl:variable name="subjectString_raw">
                    <xsl:value-of select="marc:subfield" separator="--"/>
                </xsl:variable>
                <xsl:value-of select="replace(replace($subjectString_raw,' ',' '),'\.$','')"/>
            </xsl:variable>
            <xsl:call-template name="lcsh2fast">
                <xsl:with-param name="subjectString" select="$subjectString"/>
            </xsl:call-template>
        </xsl:for-each>
        <!-- MARC 651 -->
        <xsl:for-each select="marc:datafield[@tag=651][@ind2=0]">
            <xsl:choose>
                <xsl:when test="marc:subfield[@code='y']">
                    <xsl:choose>
                        <!-- If $y pattern matches YYYY-YYYY or YYYY-  or contains "century" or "B.C." and no comma -->
                        <xsl:when test="not(matches(marc:subfield[@code='y'],',')) and (matches(marc:subfield[@code='y'],'\d+\-\d*') or matches(marc:subfield[@code='y'],'century','i') or matches(marc:subfield[@code='y'],'B.C.','i'))">
                            <!-- $a -->
                            <xsl:for-each select="marc:subfield[@code='a']">
                                <xsl:call-template name="lc2fast_subfield">
                                    <xsl:with-param name="subfield_code">z</xsl:with-param>
                                </xsl:call-template>
                                <xsl:call-template name="lc2fast_subfield_search">
                                    <xsl:with-param name="search_index">oclc.altlc</xsl:with-param>
                                </xsl:call-template>
                            </xsl:for-each>
                            <!-- Not subfield $a -->
                            <xsl:call-template name="subdivision_x_processing"/>
                            <xsl:call-template name="subdivision_vy_processing"/>
                            <xsl:call-template name="subdivision_y_processing"/>
                            <xsl:call-template name="subdivision_z_processing"/>
                        </xsl:when>
                        <!-- If other $y patterns -->
                        <xsl:otherwise>
                            <xsl:variable name="subjectString">
                                <xsl:variable name="subjectString_raw">
                                    <xsl:value-of select="marc:subfield" separator="--"/>
                                </xsl:variable>
                                <xsl:value-of select="replace(replace($subjectString_raw,' ',' '),'\.$','')"/>
                            </xsl:variable>
                            <xsl:call-template name="lcsh2fast">
                                <xsl:with-param name="subjectString" select="$subjectString"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="subdivision_x_processing"/>
                    <xsl:call-template name="subdivision_vy_processing"/>
                    <xsl:call-template name="subdivision_y_processing"/>
                    <xsl:call-template name="subdivision_z_processing"/>
                    <xsl:for-each select="marc:subfield[@code='a']">
                        <xsl:call-template name="lc2fast_subfield">
                            <xsl:with-param name="subfield_code">z</xsl:with-param>
                        </xsl:call-template>
                        <xsl:call-template name="lc2fast_subfield_search">
                            <xsl:with-param name="search_index">oclc.altlc</xsl:with-param>
                        </xsl:call-template>                      
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <!-- MARC 655 -->
        <xsl:for-each select="marc:datafield[@tag=655][@ind2=0]|marc:datafield[@tag=655][@ind2=7][replace(marc:subfield[@code='2'],'\.$','')='lcgft']">
            <xsl:for-each select="marc:subfield[@code='a']">
                <xsl:call-template name="lc2fast_subfield">
                    <xsl:with-param name="subfield_code">v</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Identity transform -->
    <xsl:template match="@*|node()" mode="all_copy">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*|node()" mode="all_copy"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Sudivision templates -->
    <!-- Template for subdivision X -->
    <xsl:template name="subdivision_x_processing">
        <!-- All subfield x -->
        <xsl:variable name="topical_fast">
            <xsl:for-each select="marc:subfield[@code='x'][1]">
                <xsl:variable name="topical_subdivision">
                    <xsl:value-of select="replace(text(),'\.$','')"/>
                    <xsl:for-each select="following-sibling::marc:subfield[@code='x']">
                        <xsl:value-of select="concat('--',replace(text(),'\.$',''))"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:for-each select="$topical_subdivision">
                    <xsl:call-template name="lc2fast_subfield">
                        <xsl:with-param name="subfield_code">x</xsl:with-param>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <!-- If FAST matching concatenated topical subdivisions found -->
            <xsl:when test="string-length($topical_fast)!=0">
                <xsl:copy-of select="$topical_fast"/>
            </xsl:when>
            <!-- If FAST matching concatenated topical subdivisions not found -->
            <xsl:otherwise>
                <xsl:for-each select="marc:subfield[@code='x']">
                    <xsl:choose>
                        <!-- If "Topic, Date" pattern -->
                        <xsl:when test="matches(.,'\w+, \d+\-*\d*\.*$')">
                            <!-- Topical part -->
                            <xsl:for-each select="replace(.,', \d+\-*\d*\.*$','')">
                                <xsl:call-template name="lc2fast_subfield">
                                    <xsl:with-param name="subfield_code">x</xsl:with-param>
                                </xsl:call-template> 
                            </xsl:for-each>
                            <!-- Temporal part -->
                            <xsl:variable name="temporal">
                                <marc:subfield code="y">
                                    <xsl:value-of select="replace(.,'[\D-[\-]]','')"/>
                                </marc:subfield>
                            </xsl:variable>
                            <xsl:for-each select="$temporal">
                                <xsl:call-template name="subdivision_y_processing"/>
                            </xsl:for-each>
                        </xsl:when>
                        <!-- If not "Topic, Date" pattern -->
                        <xsl:otherwise>
                            <xsl:call-template name="lc2fast_subfield">
                                <xsl:with-param name="subfield_code">x</xsl:with-param>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Template for subdivisions V & Y -->
    <!-- Subfields $v & $y -->
    <xsl:template name="subdivision_vy_processing">
        <xsl:for-each select="marc:subfield[@code='v' or @code='y']">
            <xsl:call-template name="lc2fast_subfield">
                <xsl:with-param name="subfield_code" select="@code"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    <!-- Template for subdivision Y -->
    <!-- Subfield $y -->
    <xsl:template name="subdivision_y_processing">
        <xsl:for-each select="marc:subfield[@code='y']">
            <!-- Matches YYYY-YYYY pattern -->
            <xsl:if test="matches(replace(.,'\.$',''),'\d+\s?\w*\-\d+\s?\w*') and not(matches(.,','))">
                <marc:datafield tag="648" ind1=" " ind2="7">
                    <marc:subfield code="a">
                        <xsl:value-of select="normalize-space(replace(replace(text(),'\-',' - '),'\.$',''))"/>
                    </marc:subfield>
                    <marc:subfield code="2">fast</marc:subfield>
                </marc:datafield>
            </xsl:if>
            <!-- Matches YYYY- pattern -->
            <xsl:if test="matches(replace(.,'\.$',''),'\d+\s?\w*\-$') and not(matches(.,','))">
                <marc:datafield tag="648" ind1=" " ind2="7">
                    <marc:subfield code="a">
                        <xsl:text>Since </xsl:text>
                        <xsl:value-of select="replace(text(),'\-','')"/>
                    </marc:subfield>
                    <marc:subfield code="2">fast</marc:subfield>
                </marc:datafield>
            </xsl:if>
            <!-- Matches YYYY pattern -->
            <xsl:if test="matches(replace(.,'\.$',''),'\d+\s?\w*$') and not(matches(.,',')) and not(matches(.,'\-'))">
                <marc:datafield tag="648" ind1=" " ind2="7">
                    <marc:subfield code="a">
                        <xsl:value-of select="replace(text(),'\.$','')"/>
                    </marc:subfield>
                    <marc:subfield code="2">fast</marc:subfield>
                </marc:datafield>
            </xsl:if>
            <!-- Matches "century" pattern -->
            <xsl:if test="matches(.,'century','i') and not(matches(.,','))">
                <marc:datafield tag="648" ind1=" " ind2="7">
                    <marc:subfield code="a">
                        <xsl:if test="matches(.,'21st','i')">2000 - 2099</xsl:if>
                        <xsl:if test="matches(.,'20th','i')">1900 - 1999</xsl:if>
                        <xsl:if test="matches(.,'19th','i')">1800 - 1899</xsl:if>
                        <xsl:if test="matches(.,'18th','i')">1700 - 1799</xsl:if>
                        <xsl:if test="matches(.,'17th','i')">1600 - 1699</xsl:if>
                        <xsl:if test="matches(.,'16th','i')">1500 - 1599</xsl:if>
                        <xsl:if test="matches(.,'15th','i')">1400 - 1499</xsl:if>
                        <xsl:if test="matches(.,'14th','i')">1300 - 1399</xsl:if>
                        <xsl:if test="matches(.,'13th','i')">1200 - 1299</xsl:if>
                        <xsl:if test="matches(.,'12th','i')">1100 - 1199</xsl:if>
                        <xsl:if test="matches(.,'11th','i')">1000 - 1099</xsl:if>
                        <xsl:if test="matches(.,'10th','i')">900 - 999</xsl:if>
                        <xsl:if test="matches(.,'^9th','i')">800 - 899</xsl:if>
                        <xsl:if test="matches(.,'^8th','i')">700 - 799</xsl:if>
                        <xsl:if test="matches(.,'^7th','i')">600 - 699</xsl:if>
                        <xsl:if test="matches(.,'^6th','i')">500 - 599</xsl:if>
                        <xsl:if test="matches(.,'^5th','i')">400 - 499</xsl:if>
                        <xsl:if test="matches(.,'^4th','i')">300 - 399</xsl:if>
                        <xsl:if test="matches(.,'^3rd','i')">200 - 299</xsl:if>
                        <xsl:if test="matches(.,'^2nd','i')">100 - 199</xsl:if>
                        <xsl:if test="matches(.,'^1st','i')">0 B.C. - 99 A.D.</xsl:if>
                    </marc:subfield>
                    <marc:subfield code="2">fast</marc:subfield>
                </marc:datafield>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <!-- Tempalte for subdivision Z -->
    <xsl:template name="subdivision_z_processing">
        <!-- All subfields $z -->
        <xsl:for-each select="marc:subfield[@code='z'][1]">
            <xsl:variable name="geographic_subdivision">
                <xsl:value-of select="replace(text(),'\.$','')"/>
                <xsl:for-each select="following-sibling::marc:subfield[@code='z']">
                    <xsl:value-of select="concat('--',replace(text(),'\.$',''))"/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:for-each select="$geographic_subdivision">
                <xsl:call-template name="lc2fast_subfield">
                    <xsl:with-param name="subfield_code">z</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Conference name template -->
    <xsl:template name="conf-corp_name_processing">
        <!-- Conference Name entry -->
        <xsl:if test="marc:subfield[@code='n' or @code='d' or @code='c']">
            <!-- Individual Conference Name entry -->
            <xsl:variable name="subjectString">
                <xsl:variable name="subjectString_raw">
                    <xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='n']">
                        <xsl:if test="@node='a' or @code='n' or @code='d' or @code='c'">
                            <xsl:value-of select="."/>
                        </xsl:if>
                        <xsl:if test="@code='b'">
                            <xsl:value-of select="concat('. ',.)"/>    
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:value-of select="replace(replace(normalize-space($subjectString_raw),'\.\.','.'),'\.$','')"/>
            </xsl:variable>
            <xsl:for-each select="$subjectString">
                <xsl:call-template name="lc2fast_subfield">
                    <xsl:with-param name="subfield_code">e</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
            <!-- Collective Conference Name entry -->
            <xsl:variable name="subjectString">
                <xsl:variable name="subjectString_raw">
                    <xsl:for-each select="marc:subfield[@code='a' or @code='b']">
                        <xsl:if test="@node='a'">
                            <xsl:value-of select="."/>
                        </xsl:if>
                        <xsl:if test="@code='b'">
                            <xsl:value-of select="concat('. ',.)"/>    
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:value-of select="replace(replace(normalize-space($subjectString_raw),'\.\.','.'),'\.$','')"/>
            </xsl:variable>
            <xsl:for-each select="$subjectString">
                <xsl:call-template name="lc2fast_subfield">
                    <xsl:with-param name="subfield_code">e</xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
        <!-- Corporate Name entry -->
        <xsl:variable name="subjectString">
            <xsl:variable name="subjectString_raw">
                <xsl:for-each select="marc:subfield[@code='a' or @code='b']">
                    <xsl:if test="@code='a'">
                        <xsl:value-of select="."/>
                    </xsl:if>
                    <xsl:if test="@code='b'">
                        <xsl:value-of select="concat('. ',.)"/>    
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="replace(replace(normalize-space($subjectString_raw),'\.\.','.'),'\.$','')"/>
        </xsl:variable>
        <!-- Try Corporate Name -->
        <xsl:for-each select="$subjectString">
            <xsl:call-template name="lc2fast_subfield">
                <xsl:with-param name="subfield_code">c</xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
        <!-- Try Collective Conference Name -->
        <xsl:for-each select="$subjectString">
            <xsl:call-template name="lc2fast_subfield">
                <xsl:with-param name="subfield_code">e</xsl:with-param>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <!--<!-\- Template to flip LCSH to FAST -\->
    <xsl:template name="lcsh2fast">
        <xsl:param name="subjectString"/>
        <xsl:variable name="subjectString_urlEncode" select="encode-for-uri($subjectString)"/>
        <xsl:for-each select="doc(concat('https://experimental.worldcat.org/fast/search?query=oclc.altlc+all+%22',replace($subjectString_urlEncode,' ','%20'),'%22&amp;sortKeys=usage&amp;maximumRecords=5000&amp;httpAccept=application/xml'))">
            <xsl:choose>
                <!-\- If match found in above -\->
                <xsl:when test="//marc:record">
                    <xsl:for-each select="//marc:record">
                        <xsl:call-template name="finding_matches">
                            <xsl:with-param name="subjectString" select="$subjectString"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
                <!-\- If no matching FAST heading -\->
                <!-\-<xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="contains($subjectString,'-\\-')">
                            <xsl:variable name="last_subdivision">
                                <xsl:call-template name="last_subdivision">
                                    <xsl:with-param name="subjectString" select="$subjectString"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="lcsh2fast">
                                <xsl:with-param name="subjectString" select="replace(replace($subjectString,concat('-\\-',$last_subdivision),''),'\.$','')"/>
                            </xsl:call-template>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>-\->
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>-->
    
    <!-- Template to flip LCSH to FAST -->
    <xsl:template name="lcsh2fast">
        <xsl:param name="subjectString"/>
        <xsl:for-each select="doc(concat('https://experimental.worldcat.org/fast/search?query=oclc.altlc+all+&quot;',$subjectString,'&quot;&amp;sortKeys=usage&amp;httpAccept=application/xml'))">
            <xsl:choose>
                <!-- If match found in above -->
                <xsl:when test="//marc:record">
                    <xsl:for-each select="//marc:record">
                        <xsl:call-template name="finding_matches">
                            <xsl:with-param name="subjectString" select="$subjectString"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
                <!-- If no matching FAST heading -->
                <!--<xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="contains($subjectString,'-\-')">
                            <xsl:variable name="last_subdivision">
                                <xsl:call-template name="last_subdivision">
                                    <xsl:with-param name="subjectString" select="$subjectString"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:call-template name="lcsh2fast">
                                <xsl:with-param name="subjectString" select="replace(replace($subjectString,concat('-\-',$last_subdivision),''),'\.$','')"/>
                            </xsl:call-template>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>-->
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="lc2fast_subfield">
        <xsl:param name="subfield_code"/>
        <xsl:if test="$subfield_code='x'">
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">oclc.topic</xsl:with-param>
            </xsl:call-template>
            <!--<xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">oclc.form</xsl:with-param>
            </xsl:call-template>-->
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">cql.any</xsl:with-param>
            </xsl:call-template>
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">oclc.altlc</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$subfield_code='y'">
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">oclc.period</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$subfield_code='z'">
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">oclc.geographic</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$subfield_code='p'">
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">oclc.personalName</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$subfield_code='c'">
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">oclc.corporateName</xsl:with-param>
            </xsl:call-template>
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">cql.any</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$subfield_code='e'">
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">oclc.eventName</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$subfield_code='t'">
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">oclc.uniformTitle</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="$subfield_code='v'">
            <xsl:call-template name="lc2fast_subfield_search">
                <xsl:with-param name="search_index">oclc.form</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!--<xsl:template name="lc2fast_subfield_search">
        <xsl:param name="search_index"/>
        <xsl:param name="subjectString">
            <xsl:analyze-string select="." regex=".+\s.\.$">
                <xsl:matching-substring>
                    <xsl:value-of select="."/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="replace(.,'\.$','')"/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:param>
        <xsl:variable name="subjectString_urlEncode" select="encode-for-uri($subjectString)"/>
        <xsl:for-each select="doc(concat('https://experimental.worldcat.org/fast/search?query=',$search_index,'+all+%22',replace($subjectString_urlEncode,' ','%20'),'%22&amp;sortKeys=usage&amp;maximumRecords=5000&amp;httpAccept=application/xml'))">
            <xsl:call-template name="search_result_processing">
                <xsl:with-param name="subjectString" select="$subjectString"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>-->
    
    <xsl:template name="lc2fast_subfield_search">
        <xsl:param name="search_index"/>
        <xsl:param name="subjectString">
            <xsl:analyze-string select="." regex=".+\s.\.$">
                <xsl:matching-substring>
                    <xsl:value-of select="."/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="replace(.,'\.$','')"/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:param>
        <!-- TO DO why was this commented out before -->
        <!--<xsl:for-each select="doc(concat('https://experimental.worldcat.org/fast/search?query=',$search_index,'+all+&quot;',$subjectString,'&quot;&amp;maximumRecords=100000&amp;httpAccept=application/xml'))">
            <xsl:call-template name="search_result_processing">
                <xsl:with-param name="subjectString" select="$subjectString"/>
            </xsl:call-template>
        </xsl:for-each>-->
        <xsl:param name="searchResults">
            <xsl:call-template name="searchResultPaging">
                <xsl:with-param name="nextRecordPosition" select="'1'"/>
                <xsl:with-param name="search_index" select="$search_index"/>
                <xsl:with-param name="subjectString" select="$subjectString"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:for-each select="$searchResults">
            <xsl:call-template name="search_result_processing">
                <xsl:with-param name="subjectString" select="$subjectString"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="search_result_processing">
        <xsl:param name="subjectString"/>
        <xsl:param name="result">
            <xsl:for-each select="//marc:record">
                <xsl:call-template name="finding_matches">
                    <xsl:with-param name="subjectString" select="$subjectString"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:param>
        <xsl:choose>
            <xsl:when test="$result//marc:datafield">
                <xsl:copy-of select="$result"/>
            </xsl:when>
            <!--<xsl:otherwise>
                <xsl:call-template name="lcSubdivisionHeading780_processing">
                    <xsl:with-param name="searchXML">
                        <xsl:element name="marc:collection">
                            <xsl:copy-of select="//marc:record"/>
                        </xsl:element>
                    </xsl:with-param>
                    <xsl:with-param name="result" select="$result"/>
                    <xsl:with-param name="subjectString" select="$subjectString"/>
                </xsl:call-template>
            </xsl:otherwise>-->
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="searchResultPaging">
        <xsl:param name="subjectString"/>
        <xsl:param name="search_index"/>
        <xsl:param name="nextRecordPosition"/>
        <xsl:for-each select="doc(concat('http://experimental.worldcat.org/fast/search?query=',$search_index,'+all+%22',encode-for-uri($subjectString),'%22&amp;startRecord=',$nextRecordPosition,'&amp;sortKey=usage&amp;httpAccept=application/xml'))">
            <xsl:choose>
                <xsl:when test="//srw:nextRecordPosition">
                    <xsl:copy-of select="//srw:record"/>
                    <xsl:call-template name="searchResultPaging">
                        <xsl:with-param name="nextRecordPosition" select="//srw:nextRecordPosition/text()"/>
                        <xsl:with-param name="search_index" select="$search_index"/>
                        <xsl:with-param name="subjectString" select="$subjectString"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="self::node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
        
    <!-- Template to process topical subdivision when no matches found -->
    <xsl:template name="lcSubdivisionHeading780_processing">
        <xsl:param name="searchXML"/>
        <xsl:param name="subjectString"/>
        <xsl:param name="result"/>
        <xsl:choose>
            <xsl:when test="not($result//marc:datafield)">
                <xsl:for-each select="$searchXML">
                    <xsl:for-each select="marc:collection/marc:record[1]">
                        <xsl:variable name="result">
                            <!-- Extract LC subdivision heading -->
                            <xsl:variable name="lcSubdivisionHeading">
                                <xsl:for-each select="marc:datafield[@tag=750][@ind2=0][marc:subfield[@code='x']]|marc:datafield[@tag=780][@ind2=0]">
                                    <xsl:value-of select="marc:subfield[@code='x']" separator="--"/>
                                </xsl:for-each>
                            </xsl:variable>
                            <!-- If subject string matches 780 LCSH subdivision -->
                            <xsl:if test="replace($lcSubdivisionHeading,'( |\p{P})','')=replace($subjectString,'( |\p{P})','')">
                                <xsl:for-each select="marc:datafield[@tag=150]">
                                    <!-- Create marc:datafield -->
                                    <marc:datafield tag="6{substring(@tag,2)}" ind1="{@ind1}" ind2="7">
                                        <xsl:for-each select="marc:subfield">
                                            <marc:subfield code="{@code}">
                                                <xsl:value-of select="."/>
                                            </marc:subfield>
                                        </xsl:for-each>
                                        <marc:subfield code="2">fast</marc:subfield>
                                        <xsl:for-each select="preceding-sibling::marc:controlfield[@tag=001]">
                                            <marc:subfield code="0">
                                                <xsl:value-of select="concat('http://id.worldcat.org/fast/',replace(replace(replace(replace(replace(replace(replace(replace(replace(.,'fst',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''))"/>
                                            </marc:subfield>
                                        </xsl:for-each>
                                    </marc:datafield>
                                </xsl:for-each>
                            </xsl:if>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$result//marc:datafield">
                                <xsl:copy-of select="$result"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:choose>
                                    <xsl:when test="count($searchXML//marc:record)!=1">
                                        <xsl:call-template name="lcSubdivisionHeading780_processing">
                                            <xsl:with-param name="searchXML">
                                                <xsl:element name="marc:collection">
                                                    <xsl:for-each select="$searchXML/marc:collection">
                                                        <xsl:copy-of select="marc:record[position()!=1]"/>
                                                    </xsl:for-each>
                                                </xsl:element>
                                            </xsl:with-param>
                                            <xsl:with-param name="result" select="$result"/>
                                            <xsl:with-param name="subjectString" select="$subjectString"/>
                                        </xsl:call-template>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="last_subdivision">
        <xsl:param name="subjectString"/>
        <xsl:choose>
            <xsl:when test="contains($subjectString,'--')">
                <xsl:call-template name="last_subdivision">
                    <xsl:with-param name="subjectString" select="substring-after($subjectString,'--')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$subjectString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Template to select and verify FAST headings returned -->
    <xsl:template name="finding_matches">
        <xsl:param name="subjectString"/>
        <!-- Extract LC heading -->
        <xsl:variable name="lcHeading">
            <xsl:variable name="lcheading_raw">
                <!-- removed ind2='0' for 780 field to bypass OCLC coding error 2/6/18 -ll -->
                <!-- ll note 9/4, removing 730 from this line fixes issue with incorrectly added uniform titles -->
                <xsl:for-each select="marc:datafield[@tag=700][@ind2=0]|marc:datafield[@tag=710][@ind2=0]|marc:datafield[@tag=711][@ind2=0]|marc:datafield[@tag=750][@ind2=0]|marc:datafield[@tag=751][@ind2=0]|marc:datafield[@tag=755][@ind2=0]|marc:datafield[@tag=755][@ind2=7][replace(marc:subfield[@code='2'],'\.$','')='lcgft']|marc:datafield[@tag=780]">
                    <marc:datafield tag="{@tag}" ind1=" " ind2=" ">
                        <xsl:copy-of select="marc:subfield[not(@code='0') and not(@code='w') and not(@code='2') and not(@code='9')]"/>
                    </marc:datafield>
                </xsl:for-each>
            </xsl:variable>
            <xsl:for-each-group select="$lcheading_raw/marc:datafield" group-by=".">
                <xsl:value-of select="marc:subfield" separator=" "/>        
            </xsl:for-each-group>
        </xsl:variable>
        <!-- Extract FAST heading in 1XX -->
        <xsl:variable name="fastHeading">
            <!-- removed 130 and 155 to prevent adding duplicate/incorrect matches to topical subjects -->
            <xsl:for-each select="marc:datafield[@tag=100]|marc:datafield[@tag=110]|marc:datafield[@tag=111]|marc:datafield[@tag=147]|marc:datafield[@tag=148]|marc:datafield[@tag=150]|marc:datafield[@tag=151]">
                <xsl:value-of select="marc:subfield" separator=" "/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <!-- If LC heading in FAST record or FAST heading in 1XX matches search string -->
            <xsl:when test="lower-case(replace($lcHeading,'( |\p{P})',''))=lower-case(replace($subjectString,'( |\p{P})','')) or lower-case(replace($subjectString,'( |\p{P})',''))=lower-case(replace($fastHeading,'( |\p{P})',''))">
                <xsl:choose>
                    <!-- If FAST heading is obsolete -->
                    <!--<xsl:when test="marc:datafield[@tag=700][marc:subfield[@code='2']='fast'] or 
                        marc:datafield[@tag=710][marc:subfield[@code='2']='fast'] or marc:datafield[@tag=711][marc:subfield[@code='2']='fast'] or 
                        marc:datafield[@tag=730][marc:subfield[@code='2']='fast'] or marc:datafield[@tag=748][marc:subfield[@code='2']='fast'] or 
                        marc:datafield[@tag=750][marc:subfield[@code='2']='fast'] or marc:datafield[@tag=751][marc:subfield[@code='2']='fast'] or 
                        marc:datafield[@tag=755][marc:subfield[@code='2']='fast']">
                        <xsl:for-each select="marc:datafield[@tag=700][marc:subfield[@code='2']='fast']|marc:datafield[@tag=710][marc:subfield[@code='2']='fast']|marc:datafield[@tag=711][marc:subfield[@code='2']='fast']|marc:datafield[@tag=730][marc:subfield[@code='2']='fast']|marc:datafield[@tag=748][marc:subfield[@code='2']='fast']|marc:datafield[@tag=750][marc:subfield[@code='2']='fast']|marc:datafield[@tag=751][marc:subfield[@code='2']='fast']|marc:datafield[@tag=755][marc:subfield[@code='2']='fast']">
                            <!-\- Create marc:datafield -\->
                            <marc:datafield tag="6{substring(@tag,2)}" ind1="{@ind1}" ind2="7">
                                <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='w')]">
                                    <marc:subfield code="{@code}">
                                        <xsl:value-of select="."/>
                                    </marc:subfield>
                                </xsl:for-each>
                                <xsl:for-each select="marc:subfield[@code='0']">
                                    <marc:subfield code="0">
                                        <xsl:value-of select="concat('http://id.worldcat.org/fast/',replace(replace(replace(replace(replace(replace(replace(replace(replace(.,'\(OCoLC\)fst',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''))"/>
                                    </marc:subfield>
                                </xsl:for-each>
                            </marc:datafield>
                        </xsl:for-each>
                    </xsl:when>-->
                    <!-- -ll changed 9.4.18 to avoid issue where heading 'Public opinion' also added an incorrect heading for 'European Union' due to the obsolete heading record European Union-\-Public opinion -->
                    <xsl:when test="substring(marc:leader,6,1) = 'x' or substring(marc:leader,6,1) = 'd' or substring(marc:leader,6,1) = 'o' or substring(marc:leader,6,1) = 's'"/>
                    <!-- If FAST heading is current -->
                    <xsl:otherwise>
                        <!-- Check if topical FAST heading has more subfields than LC 7XX -->
                        <xsl:variable name="count7xx">
                            <xsl:variable name="lc_heading_subfields">
                                <xsl:for-each select="marc:datafield[@tag=750][@ind2=0]|marc:datafield[@tag=751][@ind2=0]|marc:datafield[@tag=755][@ind2=0]|marc:datafield[@tag=755][@ind2=7][replace(marc:subfield[@code='2'],'\.$','')='lcgft']|marc:datafield[@tag=780][@ind2=0]">
                                    <xsl:copy-of select="marc:subfield[not(@code='0') and not(@code='w') and not(@code='2') and not(@code='9')]"/>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:variable name="unique_groups">
                                <xsl:for-each-group select="$lc_heading_subfields/marc:subfield" group-by=".">
                                    <xsl:value-of select="count(current-group())"/>        
                                </xsl:for-each-group>
                            </xsl:variable>
                            <xsl:value-of select="string-length($unique_groups)"/>
                        </xsl:variable>
                        <xsl:variable name="count1xx">
                            <xsl:for-each select="marc:datafield[@tag=100]|marc:datafield[@tag=110]|marc:datafield[@tag=111]|marc:datafield[@tag=147]|marc:datafield[@tag=148]|marc:datafield[@tag=150]|marc:datafield[@tag=151]|marc:datafield[@tag=155]">
                                <xsl:value-of select="count(marc:subfield)"/> 
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:if test="($count1xx &lt;= $count7xx) or marc:datafield[@tag=100 or @tag=110 or @tag=130 or @tag=111 or @tag=147 or @tag=148 or @tag=151 or @tag=155]">
                            <xsl:for-each select="marc:datafield[@tag=100]|marc:datafield[@tag=110]|marc:datafield[@tag=111]|marc:datafield[@tag=130]|marc:datafield[@tag=147]|marc:datafield[@tag=150]|marc:datafield[@tag=151]|marc:datafield[@tag=155]">
                                <!-- Create marc:datafield -->
                                <marc:datafield tag="6{substring(@tag,2)}" ind1="{@ind1}" ind2="7">
                                    <xsl:for-each select="marc:subfield">
                                        <marc:subfield code="{@code}">
                                            <xsl:value-of select="."/>
                                        </marc:subfield>
                                    </xsl:for-each>
                                    <marc:subfield code="2">fast</marc:subfield>
                                    <xsl:for-each select="preceding-sibling::marc:controlfield[@tag=001]">
                                        <marc:subfield code="0">
                                            <xsl:value-of select="concat('http://id.worldcat.org/fast/',replace(replace(replace(replace(replace(replace(replace(replace(replace(.,'fst',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''),'^0',''))"/>
                                        </marc:subfield>
                                    </xsl:for-each>
                                </marc:datafield>
                            </xsl:for-each>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- Generate FAST chronological heading from 046 -->
                <xsl:if test="marc:datafield[@tag=111] or marc:datafield[@tag=147]">
                    <xsl:call-template name="fastFrom046"/>
                </xsl:if>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- Template to generate FAST chronological heading from 046 -->
    <xsl:template name="fastFrom046">
        <xsl:for-each select="marc:datafield[@tag=046][marc:subfield[@code='s' or @code='t']]">
            <marc:datafield tag="648" ind1=" " ind2="7">
                <marc:subfield code="a">
                    <xsl:value-of select="replace(replace(concat(marc:subfield[@code='s'],' - ',marc:subfield[@code='t']),'\-$',''),' \- $','')"/>
                </marc:subfield>
                <marc:subfield code="2">fast</marc:subfield>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Template to flip MODS into MARC -->
    <xsl:template name="mods2marc">
        <!-- mods:name -->
        <xsl:for-each select="child::node()[1][local-name()='name']">
            <!-- personal name -->
            <xsl:if test="@type='personal'">
                <marc:datafield tag="600" ind1="1" ind2="0">
                    <marc:subfield code="a">
                        <xsl:value-of select="mods:namePart[1],mods:namePart[@type='family'],mods:namePart[@type='given']" separator=" "/>    
                    </marc:subfield>
                    <xsl:for-each select="mods:namePart[position()!=1]">
                        <xsl:call-template name="mods2marc_subject_subdivision"/>
                    </xsl:for-each>
                    <xsl:for-each select="following-sibling::node()">
                        <xsl:call-template name="mods2marc_subject_subdivision"/>
                    </xsl:for-each>
                </marc:datafield>
            </xsl:if>
            <!-- corporate name -->
            <xsl:if test="@type='corporate'">
                <marc:datafield tag="610" ind1="2" ind2="0">
                    <xsl:for-each select="mods:namePart[1]">
                        <marc:subfield code="a">
                            <xsl:value-of select="concat(.,'.')"/>
                        </marc:subfield>
                    </xsl:for-each>
                    <xsl:for-each select="mods:namePart[position()!=1 and position()!=last()]">
                        <marc:subfield code="b">
                            <xsl:value-of select="concat(.,'.')"/>
                        </marc:subfield>
                    </xsl:for-each>
                    <xsl:for-each select="mods:namePart[position()!=1 and position()=last()]">
                        <marc:subfield code="b">
                            <xsl:value-of select="."/>
                        </marc:subfield>
                    </xsl:for-each>
                    <xsl:for-each select="following-sibling::node()">
                        <xsl:call-template name="mods2marc_subject_subdivision"/>
                    </xsl:for-each>
                </marc:datafield>
            </xsl:if>
            <!-- conference name -->
            <xsl:if test="@type='conference'">
                <marc:datafield tag="611" ind1="2" ind2="0">
                    <xsl:for-each select="mods:namePart[1]">
                        <marc:subfield code="a">
                            <xsl:value-of select="concat(.,'.')"/>
                        </marc:subfield>
                    </xsl:for-each>
                    <xsl:for-each select="mods:namePart[position()!=1 and position()!=last()]">
                        <marc:subfield code="b">
                            <xsl:value-of select="concat(.,'.')"/>
                        </marc:subfield>
                    </xsl:for-each>
                    <xsl:for-each select="mods:namePart[position()!=1 and position()=last()]">
                        <marc:subfield code="b">
                            <xsl:value-of select="."/>
                        </marc:subfield>
                    </xsl:for-each>
                    <xsl:for-each select="following-sibling::node()">
                        <xsl:call-template name="mods2marc_subject_subdivision"/>
                    </xsl:for-each>
                </marc:datafield>
            </xsl:if>
            <!-- family name -->
            <xsl:if test="@type='family'">
                <marc:datafield tag="600" ind1="3" ind2="0">
                    <marc:subfield code="a">
                        <xsl:value-of select="mods:namePart" separator=" "/>    
                    </marc:subfield>
                    <xsl:for-each select="following-sibling::node()">
                        <xsl:call-template name="mods2marc_subject_subdivision"/>
                    </xsl:for-each>
                </marc:datafield>
            </xsl:if>
        </xsl:for-each>
        <!-- mods:topic -->
        <xsl:for-each select="self::mods:subject[child::node()[1][local-name()='topic']]">
            <marc:datafield tag="650" ind1=" " ind2="0">
                <marc:subfield code="a">
                    <xsl:value-of select="child::node()[1]"/>
                </marc:subfield>
                <xsl:for-each select="child::node()[position()!=1]">
                    <xsl:call-template name="mods2marc_subject_subdivision"/>
                </xsl:for-each>
            </marc:datafield>
        </xsl:for-each>
        <!-- mods:titleInfo -->
        <xsl:for-each select="self::mods:subject[child::node()[1][local-name()='titleInfo']]">
            <marc:datafield tag="630" ind1="0" ind2="0">
                <marc:subfield code="a">
                    <xsl:value-of select="mods:nonSort,mods:title" separator=" "/>
                </marc:subfield>
                <xsl:for-each select="mods:subTitle">
                    <marc:subfield code="b">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:partNumber">
                    <marc:subfield code="n">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
                <xsl:for-each select="mods:partName">
                    <marc:subfield code="p">
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:for-each>
            </marc:datafield>
        </xsl:for-each>
        <!-- mods:geographic -->
        <xsl:for-each select="self::mods:subject[child::node()[1][local-name()='geographic']]">
            <marc:datafield tag="651" ind1=" " ind2="0">
                <marc:subfield code="a">
                    <xsl:value-of select="child::node()[1]"/>
                </marc:subfield>
                <xsl:for-each select="child::node()[position()!=1]">
                    <xsl:call-template name="mods2marc_subject_subdivision"/>
                </xsl:for-each>
            </marc:datafield>
        </xsl:for-each>
        <!-- mods:genre -->
        <xsl:for-each select="self::mods:genre">
            <marc:datafield tag="655" ind1=" " ind2="7">
                <marc:subfield code="a">
                    <xsl:value-of select="text()"/>
                </marc:subfield>
                <marc:subfield code="2">
                    <xsl:text>lcgft</xsl:text>
                </marc:subfield>
            </marc:datafield>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Template to dedup & sort MARC output -->
    <xsl:template name="sort_and_dedup_marc">
        <xsl:param name="output_raw"/>
        <xsl:for-each-group select="$output_raw//marc:leader|$output_raw//marc:controlfield|$output_raw//marc:datafield" group-by="." >
            <xsl:sort select="concat(@tag,@ind2)"/>
            <xsl:copy-of select="."/>
        </xsl:for-each-group>
    </xsl:template>
    
    <!-- Template to dedup & sort MODS output -->
    <xsl:template name="sort_and_dedup_mods">
        <xsl:param name="output_raw"/>
        <xsl:for-each select="$output_raw">
            <!-- Export disctinct MODS elements only -->
            <xsl:copy-of select="*[not(self::mods:subject) and not(self::mods:genre) and not(self::mods:recordInfo)]"/>
            <!-- Export disctinct mods:genre -->
            <xsl:for-each-group select="mods:genre" group-by="concat(@authority,.)">
                <xsl:copy-of select="."/>
            </xsl:for-each-group>
            <!-- Export disctinct mods:subject -->
            <xsl:for-each-group select="mods:subject" group-by="concat(@authority,.)">
                <xsl:copy-of select="."/>
            </xsl:for-each-group>
            <!-- Output mods:recordInfo -->
            <xsl:for-each-group select="mods:recordInfo" group-by=".">
                <xsl:copy-of select="."/>
            </xsl:for-each-group>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Template to convert MODS subject subelements to MARC -->
    <xsl:template name="mods2marc_subject_subdivision">
        <xsl:if test="name()='mods:topic'">
            <marc:subfield code='x'>
                <xsl:value-of select="."/>
            </marc:subfield>
        </xsl:if>
        <xsl:if test="name()='mods:geographic'">
            <marc:subfield code='z'>
                <xsl:value-of select="."/>
            </marc:subfield>
        </xsl:if>
        <xsl:if test="name()='mods:temporal'">
            <marc:subfield code='y'>
                <xsl:value-of select="."/>
            </marc:subfield>
        </xsl:if>
        <xsl:if test="name()='mods:titleInfo'">
            <marc:subfield code="t">
                <xsl:value-of select="mods:nonSort,mods:title,mods:subTitle" separator=" "/>
            </marc:subfield>
            <xsl:for-each select="mods:partNumber">
                <marc:subfield code="n">
                    <xsl:value-of select="."/>
                </marc:subfield>
            </xsl:for-each>
            <xsl:for-each select="mods:partName">
                <marc:subfield code="p">
                    <xsl:value-of select="."/>
                </marc:subfield>
            </xsl:for-each>
        </xsl:if>
        <xsl:if test="name()='mods:genre'">
            <marc:subfield code='v'>
                <xsl:value-of select="."/>
            </marc:subfield>
        </xsl:if>
        <xsl:if test="name()='mods:namePart'">
            <xsl:choose>
                <xsl:when test="@type='termsOfAddress'">
                    <marc:subfield code='c'>
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:when>
                <xsl:when test="@type='date'">
                    <marc:subfield code='d'>
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:when>
                <xsl:otherwise>
                    <marc:subfield code='a'>
                        <xsl:value-of select="."/>
                    </marc:subfield>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- Template to convert FAST in MARC to MODS -->
    <xsl:template name="mods_processing">
        <xsl:variable name="marc_input">
            <marc:record>
                <xsl:for-each select="mods:subject[@authority='lcsh' or @authority='naf' or not(@authority)]|mods:genre[@authority='lcgft']">
                    <xsl:call-template name="mods2marc"/>
                </xsl:for-each>
            </marc:record>
        </xsl:variable>
        <!-- Process MARC record converted from MODS -->
        <xsl:variable name="fast_output">
            <xsl:for-each select="$marc_input">
                <xsl:apply-templates select="marc:record" mode="fast"/>    
            </xsl:for-each>
        </xsl:variable>
        <!-- Output FAST personal/family name subject -->
        <xsl:for-each select="$fast_output//marc:datafield[@tag=600]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{marc:subfield[@code='0']}">
                <xsl:variable name="type">
                    <xsl:choose>
                        <xsl:when test="@ind1='3'">
                            <xsl:text>family</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>personal</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <mods:name type="{$type}">
                    <!--incorrectly separates name parts, incorrectly chops punctuation from names with initials 
                    <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='2')]">
                        <xsl:choose>
                            <xsl:when test="@code='d'">
                                <mods:namePart type="date">
                                    <xsl:value-of select="replace(.,',$','')"/>
                                </mods:namePart>
                            </xsl:when>
                            <xsl:when test="@code='b' or @code='c'">
                                <mods:namePart type="termsOfAddress">
                                    <xsl:value-of select="."/>
                                </mods:namePart>
                            </xsl:when>
                            <xsl:otherwise>
                                <mods:namePart>
                                    <xsl:value-of select="replace(.,'\.$|,$','')"/>
                                </mods:namePart>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>-->
                    <mods:namePart>
                        <xsl:variable name="nameParts-concat">
                            <xsl:for-each select="marc:subfield">
                                <xsl:choose>
                                    <xsl:when test="@code='0'"/>
                                    <xsl:when test="@code='1'"/>
                                    <xsl:when test="@code='2'"/>
                                    <xsl:when test="@code='d'"/>
                                    <xsl:when test="@code='e'"/>
                                    <xsl:when test="@code='t'"/>
                                    <xsl:when test="@code='v'"/>
                                    <xsl:when test="@code='x'"/>
                                    <xsl:when test="@code='y'"/>
                                    <xsl:when test="@code='z'"/>
                                    <xsl:when test="@code='4'"/>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat(.,' ')"/>
                                    </xsl:otherwise>
                                </xsl:choose>                        
                            </xsl:for-each>                                
                        </xsl:variable>
                        <xsl:call-template name="chopPunctuation">
                            <xsl:with-param name="chopString" select="$nameParts-concat"/>
                        </xsl:call-template>
                        <!-- add final period back in for names ending with an initial -->
                        <xsl:if test="matches($nameParts-concat,' [A-Z]{1}\.?,? ?$') or matches($nameParts-concat,' Jr\.?,? ?$') or matches($nameParts-concat,' Sr\.?,? ?$')">
                            <xsl:text>.</xsl:text>
                        </xsl:if>
                    </mods:namePart>
                    <xsl:if test="marc:subfield[@code='d']">
                        <mods:namePart type="date">
                            <xsl:call-template name="chopPunctuation">
                                <xsl:with-param name="chopString" select="marc:subfield[@code='d']"/>
                            </xsl:call-template>
                        </mods:namePart>
                    </xsl:if>
                </mods:name>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST corporate name subject -->
        <xsl:for-each select="$fast_output//marc:datafield[@tag=610]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{marc:subfield[@code='0']}">
                <mods:name type="corporate">
                    <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='2')]">
                        <mods:namePart>
                            <xsl:value-of select="replace(.,'\.$','')"/>
                            <xsl:if test="ends-with(.,'Inc.') or ends-with(.,'Co.')">
                                <xsl:text>.</xsl:text>
                            </xsl:if>
                        </mods:namePart>
                    </xsl:for-each>
                </mods:name>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST conference name subject -->
        <xsl:for-each select="$fast_output//marc:datafield[@tag=611]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{marc:subfield[@code='0']}">
                <mods:name type="conference">
                    <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='2')]">
                        <mods:namePart>
                            <xsl:value-of select="."/>
                        </mods:namePart>
                    </xsl:for-each>
                </mods:name>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST title subject -->
        <xsl:for-each select="$fast_output//marc:datafield[@tag=630]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{marc:subfield[@code='0']}">
                <mods:titleInfo>
                    <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='2')]">
                        <xsl:choose>
                            <xsl:when test="@code='n'">
                                <mods:partNumber>
                                    <xsl:value-of select="."/>
                                </mods:partNumber>
                            </xsl:when>
                            <xsl:when test="@code='p'">
                                <mods:partName>
                                    <xsl:value-of select="."/>
                                </mods:partName>
                            </xsl:when>
                            <xsl:otherwise>
                                <mods:title>
                                    <xsl:value-of select="."/>
                                </mods:title>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </mods:titleInfo>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST event subject -->
        <xsl:for-each select="$fast_output//marc:datafield[@tag=647]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{marc:subfield[@code='0']}">
                <mods:topic>
                    <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='2')]">
                        <xsl:value-of select="."/>
                        <xsl:if test="position()!=last()">
                            <xsl:text> </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </mods:topic>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST temporal subject -->
        <xsl:for-each select="$fast_output//marc:datafield[@tag=648]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast">
                <xsl:for-each select="marc:subfield[@code='a']|marc:subfield[@code='y']">
                    <mods:temporal>
                        <xsl:value-of select="."/>
                    </mods:temporal>
                </xsl:for-each>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST topical subject -->
        <xsl:for-each select="$fast_output//marc:datafield[@tag=650]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{marc:subfield[@code='0']}">
                <xsl:for-each select="marc:subfield[@code='a']|marc:subfield[@code='x']">
                    <mods:topic>
                        <xsl:value-of select="."/>
                    </mods:topic>
                </xsl:for-each>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST geographic subject -->
        <xsl:for-each select="$fast_output//marc:datafield[@tag=651]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{marc:subfield[@code='0']}">
                <xsl:for-each select="marc:subfield[@code='a']|marc:subfield[@code='z']">
                    <mods:geographic>
                        <xsl:value-of select="."/>
                    </mods:geographic>
                </xsl:for-each>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST genre -->
        <xsl:for-each select="$fast_output//marc:datafield[@tag=655]">
            <mods:genre authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{marc:subfield[@code='0']}">
                <xsl:value-of select="marc:subfield[@code='a'],marc:subfield[@code='v']" separator="--"/>
            </mods:genre>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="chopPunctuation">
        <xsl:param name="chopString"/>
        <xsl:param name="punctuation">
            <xsl:text>.:,;/ </xsl:text>
        </xsl:param>
        <xsl:variable name="length" select="string-length($chopString)"/>
        <xsl:choose>
            <xsl:when test="$length=0"/>
            <xsl:when test="contains($punctuation, substring($chopString,$length,1))">
                <xsl:call-template name="chopPunctuation">
                    <xsl:with-param name="chopString" select="substring($chopString,1,$length - 1)"/>
                    <xsl:with-param name="punctuation" select="$punctuation"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="not($chopString)"/>
            <xsl:otherwise>
                <xsl:value-of select="$chopString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
