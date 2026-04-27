# Nivel Intermedio: Imagen Alpine (Super ligera, ~20MB en lugar de 140MB)
FROM nginx:alpine

# Copiamos nuestra configuración y código
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html

# Nivel Intermedio: Seguridad (No correr como Root)
# Damos permisos al usuario 'nginx' sobre las carpetas que necesita
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && chown -R nginx:nginx /var/run/nginx.pid

# Cambiamos al usuario sin privilegios
USER nginx

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]