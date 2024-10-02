# Project Makefile
#
# A Makefile to automate setup of Django projects and related tasks
#
# https://github.com/aclark4life/project-makefile
#
# ================================================================================
# Set the default goal to be `git commit -a -m $(GIT_COMMIT_MESSAGE)` and `git push`
# ================================================================================

.DEFAULT_GOAL := git-commit-push

# ================================================================================
# Single line variables to be used by phony target rules
# ================================================================================

ADD_DIR := mkdir -pv
ADD_FILE := touch
AWS_OPTS := --no-cli-pager --output table
COPY_DIR := cp -rv
COPY_FILE := cp -v
DEL_DIR := rm -rv
DEL_FILE := rm -v
DJANGO_ADMIN_CUSTOM_APPS_FILE := backend/apps.py
DJANGO_ADMIN_CUSTOM_ADMIN_FILE := backend/admin.py
DJANGO_CLEAN_DIRS = backend contactpage dist frontend home logging_demo model_form_demo \
		     node_modules payments privacypage search sitepage siteuser unit_test_demo
DJANGO_CLEAN_FILES = .babelrc .browserslistrc .dockerignore .eslintrc .gitignore .nvmrc \
		      .stylelintrc.json Dockerfile db.sqlite3 docker-compose.yml manage.py \
		      package-lock.json package.json postcss.config.js requirements-test.txt \
		      requirements.txt
DJANGO_FRONTEND_FILES = .babelrc .browserslistrc .eslintrc .nvmrc .stylelintrc.json \
			frontend package-lock.json \
			package.json postcss.config.js
DJANGO_SETTINGS_DIR = backend/settings
DJANGO_SETTINGS_BASE_FILE = $(DJANGO_SETTINGS_DIR)/base.py
DJANGO_SETTINGS_DEV_FILE = $(DJANGO_SETTINGS_DIR)/dev.py
DJANGO_SETTINGS_PROD_FILE = $(DJANGO_SETTINGS_DIR)/production.py
DJANGO_SETTINGS_SECRET_KEY = $(shell openssl rand -base64 48)
DJANGO_URLS_FILE = backend/urls.py
EB_DJANGO_DATABASE_HOST = $(call EB_DJANGO_DATABASE,HOST)
EB_DJANGO_DATABASE_NAME = $(call EB_DJANGO_DATABASE,NAME)
EB_DJANGO_DATABASE_PASS = $(call EB_DJANGO_DATABASE,PASSWORD)
EB_DJANGO_DATABASE_URL = $(shell eb ssh -c "source /opt/elasticbeanstalk/deployment/custom_env_var; \
	    env | grep DATABASE_URL" | awk -F= '{print $$2}')
EB_DJANGO_DATABASE_USER = $(call EB_DJANGO_DATABASE,USER)
EB_DIR_NAME := .elasticbeanstalk
EB_ENV_NAME ?= $(PROJECT_NAME)-$(GIT_BRANCH)-$(GIT_REV)
EB_PLATFORM ?= "Python 3.11 running on 64bit Amazon Linux 2023"
EC2_INSTANCE_MAX ?= 1
EC2_INSTANCE_MIN ?= 1
EC2_INSTANCE_PROFILE ?= aws-elasticbeanstalk-ec2-role
EC2_INSTANCE_TYPE ?= t4g.small
EC2_LB_TYPE ?= application
EDITOR_REVIEW = subl
GIT_ADD := git add
GIT_BRANCH = $(shell git branch --show-current)
GIT_BRANCHES = $(shell git branch -a) 
GIT_CHECKOUT = git checkout
GIT_COMMIT = git commit
GIT_COMMIT_IGNORE_FILE = .gitignore
GIT_PUSH = git push
GIT_PUSH_FORCE = $(GIT_PUSH) --force-with-lease
GIT_REV = $(shell git rev-parse --short HEAD)
GIT_STATUS = git status
MONGODB_MIGRATIONS_DIR := backend/migrations
PACKAGE_NAME = $(shell echo $(PROJECT_NAME) | sed 's/-/_/g')
PAGER ?= less
PIP_DEPS = python -m pipdeptree
PIP_ENSURE = python -m ensurepip
PIP_FREEZE = python -m pip freeze
PIP_INSTALL = python -m pip install
PIP_UNINSTALL = python -m pip uninstall -y
PLONE_VERSION_FILE = https://dist.plone.org/release/6.0.11.1/constraints.txt
PROJECT_CUSTOM_FILE := project.mk
PROJECT_EMAIL := aclark@aclark.net
PROJECT_NAME = project-makefile
PYTHON_HTTP_SERVER = python -m http.server
RANDIR := $(shell openssl rand -base64 12 | sed 's/\///g')
TMPDIR := $(shell mktemp -d)
UNAME := $(shell uname)

# ================================================================================
# Include $(PROJECT_CUSTOM_FILE) if it exists
# ================================================================================

ifneq ($(wildcard $(PROJECT_CUSTOM_FILE)),)
    include $(PROJECT_CUSTOM_FILE)
endif

# ================================================================================
# Multi-line variables to be used by phony target rules
# ================================================================================

# ----------------------------------------------------------------
#  Django Custom Admin Demo
#
#  https://docs.djangoproject.com/en/5.1/ref/contrib/admin/#overriding-the-default-admin-site
# ----------------------------------------------------------------

define DJANGO_ADMIN_CUSTOM_ADMIN
from django.contrib.admin import AdminSite


class CustomAdminSite(AdminSite):
    site_header = "Project Makefile"
    site_title = "Project Makefile"
    index_title = "Project Makefile"


custom_admin_site = CustomAdminSite(name="custom_admin")
endef

define DJANGO_ADMIN_CUSTOM_APPS
from django.contrib.admin.apps import AdminConfig


class CustomAdminConfig(AdminConfig):
    default_site = "backend.admin.CustomAdminSite"
endef

define DJANGO_API_SERIALIZERS
from rest_framework import serializers
from siteuser.models import User


class UserSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = User
        fields = ["url", "username", "email", "is_staff"]
endef

define DJANGO_API_VIEWS
from ninja import NinjaAPI
from rest_framework import viewsets
from siteuser.models import User
from .serializers import UserSerializer

api = NinjaAPI()


@api.get("/hello")
def hello(request):
    return "Hello world"


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
endef

define DJANGO_DOCKER_COMPOSE
version: '3'

services:
  db:
    image: postgres:latest
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: project
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin

  web:
    build: .
    command: sh -c "python manage.py migrate && gunicorn project.wsgi:application -b 0.0.0.0:8000"
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
    environment:
      DATABASE_URL: postgres://admin:admin@db:5432/project

volumes:
  postgres_data:
endef

define DJANGO_DOCKER_FILE
FROM amazonlinux:2023
RUN dnf install -y shadow-utils python3.11 python3.11-pip make nodejs20-npm nodejs postgresql15 postgresql15-server
USER postgres
RUN initdb -D /var/lib/pgsql/data
USER root
RUN useradd wagtail
EXPOSE 8000
ENV PYTHONUNBUFFERED=1 PORT=8000
COPY requirements.txt /
RUN python3.11 -m pip install -r /requirements.txt
WORKDIR /app
RUN chown wagtail:wagtail /app
COPY --chown=wagtail:wagtail . .
USER wagtail
RUN npm-20 install; npm-20 run build
RUN python3.11 manage.py collectstatic --noinput --clear
CMD set -xe; pg_ctl -D /var/lib/pgsql/data -l /tmp/logfile start; python3.11 manage.py migrate --noinput; gunicorn backend.wsgi:application
endef

# ----------------------------------------------------------------
#  Django Frontend
#
#  For use with python-webpack-boilerplate
# ----------------------------------------------------------------

define DJANGO_FRONTEND
import React from 'react';
import { createRoot } from 'react-dom/client';
import 'bootstrap';
// import '@fortawesome/fontawesome-free/js/fontawesome';
// import '@fortawesome/fontawesome-free/js/solid';
// import '@fortawesome/fontawesome-free/js/regular';
// import '@fortawesome/fontawesome-free/js/brands';
import getDataComponents from '../dataComponents';
import UserContextProvider from '../context';
import * as components from '../components';
import "../styles/index.scss";
import "../styles/theme-blue.scss";
import "./config";

const { ErrorBoundary } = components;
const dataComponents = getDataComponents(components);
const container = document.getElementById('app');
const root = createRoot(container);
const App = () => (
    <ErrorBoundary>
      <UserContextProvider>
        {dataComponents}
      </UserContextProvider>
    </ErrorBoundary>
);
root.render(<App />);
endef

define DJANGO_FRONTEND_BABELRC
{
  "presets": [
    [
      "@babel/preset-react",
    ],
    [
      "@babel/preset-env",
      {
        "useBuiltIns": "usage",
        "corejs": "3.0.0"
      }
    ]
  ],
  "plugins": [
    "@babel/plugin-syntax-dynamic-import",
    "@babel/plugin-transform-class-properties"
  ]
}
endef

define DJANGO_FRONTEND_CLOCK
// Via ChatGPT
import React, { useState, useEffect, useCallback, useRef } from 'react';
import PropTypes from 'prop-types';

const Clock = ({ color = '#fff' }) => {
  const [date, setDate] = useState(new Date());
  const [blink, setBlink] = useState(true);
  const timerID = useRef();

  const tick = useCallback(() => {
    setDate(new Date());
    setBlink(prevBlink => !prevBlink);
  }, []);

  useEffect(() => {
    timerID.current = setInterval(() => tick(), 1000);

    // Return a cleanup function to be run on component unmount
    return () => clearInterval(timerID.current);
  }, [tick]);

  const formattedDate = date.toLocaleDateString(undefined, {
    weekday: 'short',
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });

  const formattedTime = date.toLocaleTimeString(undefined, {
    hour: 'numeric',
    minute: 'numeric',
  });

  return (
    <> 
      <div style={{ animation: blink ? 'blink 1s infinite' : 'none' }}><span className='me-2'>{formattedDate}</span> {formattedTime}</div>
    </>
  );
};

Clock.propTypes = {
  color: PropTypes.string,
};

export default Clock;
endef

define DJANGO_FRONTEND_COMPONENTS
export { default as ErrorBoundary } from './ErrorBoundary';
export { default as UserMenu } from './UserMenu';
endef

define DJANGO_FRONTEND_CONFIG
import '../utils/themeToggler.js';
// import '../utils/tinymce.js';
endef

define DJANGO_FRONTEND_CONTEXT_INDEX
export { UserContextProvider as default } from './UserContextProvider';
endef

define DJANGO_FRONTEND_CONTEXT_USER_PROVIDER
// UserContextProvider.js
import React, { createContext, useContext, useState } from 'react';
import PropTypes from 'prop-types';

const UserContext = createContext();

export const UserContextProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const login = () => {
    try {
      // Add logic to handle login, set isAuthenticated to true
      setIsAuthenticated(true);
    } catch (error) {
      console.error('Login error:', error);
      // Handle error, e.g., show an error message to the user
    }
  };

  const logout = () => {
    try {
      // Add logic to handle logout, set isAuthenticated to false
      setIsAuthenticated(false);
    } catch (error) {
      console.error('Logout error:', error);
      // Handle error, e.g., show an error message to the user
    }
  };

  return (
    <UserContext.Provider value={{ isAuthenticated, login, logout }}>
      {children}
    </UserContext.Provider>
  );
};

UserContextProvider.propTypes = {
  children: PropTypes.node.isRequired,
};

export const useUserContext = () => {
  const context = useContext(UserContext);

  if (!context) {
    throw new Error('useUserContext must be used within a UserContextProvider');
  }

  return context;
};

// Add PropTypes for the return value of useUserContext
useUserContext.propTypes = {
  isAuthenticated: PropTypes.bool.isRequired,
  login: PropTypes.func.isRequired,
  logout: PropTypes.func.isRequired,
};
endef

define DJANGO_FRONTEND_ERROR
import { Component } from 'react';
import PropTypes from 'prop-types';

class ErrorBoundary extends Component {
  constructor (props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError () {
    return { hasError: true };
  }

  componentDidCatch (error, info) {
    const { onError } = this.props;
    console.error(error);
    onError && onError(error, info);
  }

  render () {
    const { children = null } = this.props;
    const { hasError } = this.state;

    return hasError ? null : children;
  }
}

ErrorBoundary.propTypes = {
  onError: PropTypes.func,
  children: PropTypes.node,
};

export default ErrorBoundary;
endef

define DJANGO_FRONTEND_ESLINTRC
{
    "env": {
        "browser": true,
        "es2021": true,
        "node": true
    },
    "extends": [
        "eslint:recommended",
        "plugin:react/recommended"
    ],
    "overrides": [
        {
            "env": {
                "node": true
            },
            "files": [
                ".eslintrc.{js,cjs}"
            ],
            "parserOptions": {
                "sourceType": "script"
            }
        }
    ],
    "parserOptions": {
        "ecmaVersion": "latest",
        "sourceType": "module"
    },
    "plugins": [
        "react"
    ],
    "rules": {
        "no-unused-vars": "off"
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
}
endef

define DJANGO_FRONTEND_PORTAL
// Via pwellever
import React from 'react';
import { createPortal } from 'react-dom';

const parseProps = data => Object.entries(data).reduce((result, [key, value]) => {
  if (value.toLowerCase() === 'true') {
    value = true;
  } else if (value.toLowerCase() === 'false') {
    value = false;
  } else if (value.toLowerCase() === 'null') {
    value = null;
  } else if (!isNaN(parseFloat(value)) && isFinite(value)) {
    // Parse numeric value
    value = parseFloat(value);
  } else if (
    (value[0] === '[' && value.slice(-1) === ']') || (value[0] === '{' && value.slice(-1) === '}')
  ) {
    // Parse JSON strings
    value = JSON.parse(value);
  }

  result[key] = value;
  return result;
}, {});

// This method of using portals instead of calling ReactDOM.render on individual components
// ensures that all components are mounted under a single React tree, and are therefore able
// to share context.

export default function getPageComponents (components) {
  const getPortalComponent = domEl => {
    // The element's "data-component" attribute is used to determine which component to render.
    // All other "data-*" attributes are passed as props.
    const { component: componentName, ...rest } = domEl.dataset;
    const Component = components[componentName];
    if (!Component) {
      console.error(`Component "$${componentName}" not found.`);
      return null;
    }
    const props = parseProps(rest);
    domEl.innerHTML = '';

    // eslint-disable-next-line no-unused-vars
    const { ErrorBoundary } = components;
    return createPortal(
      <ErrorBoundary>
        <Component {...props} />
      </ErrorBoundary>,
      domEl,
    );
  };

  return Array.from(document.querySelectorAll('[data-component]')).map(getPortalComponent);
}
endef

define DJANGO_FRONTEND_STYLES
// If you comment out code below, bootstrap will use red as primary color
// and btn-primary will become red

// $primary: red;

@import "~bootstrap/scss/bootstrap.scss";

.jumbotron {
  // should be relative path of the entry scss file
  background-image: url("../../vendors/images/sample.jpg");
  background-size: cover;
}

#theme-toggler-authenticated:hover {
    cursor: pointer; /* Change cursor to pointer on hover */
    color: #007bff; /* Change color on hover */
}

#theme-toggler-anonymous:hover {
    cursor: pointer; /* Change cursor to pointer on hover */
    color: #007bff; /* Change color on hover */
}
endef

define DJANGO_FRONTEND_THEME_BLUE
@import "~bootstrap/scss/bootstrap.scss";

[data-bs-theme="blue"] {
  --bs-body-color: var(--bs-white);
  --bs-body-color-rgb: #{to-rgb($$white)};
  --bs-body-bg: var(--bs-blue);
  --bs-body-bg-rgb: #{to-rgb($$blue)};
  --bs-tertiary-bg: #{$$blue-600};

  .dropdown-menu {
    --bs-dropdown-bg: #{color-mix($$blue-500, $$blue-600)};
    --bs-dropdown-link-active-bg: #{$$blue-700};
  }

  .btn-secondary {
    --bs-btn-bg: #{color-mix($gray-600, $blue-400, .5)};
    --bs-btn-border-color: #{rgba($$white, .25)};
    --bs-btn-hover-bg: #{color-adjust(color-mix($gray-600, $blue-400, .5), 5%)};
    --bs-btn-hover-border-color: #{rgba($$white, .25)};
    --bs-btn-active-bg: #{color-adjust(color-mix($gray-600, $blue-400, .5), 10%)};
    --bs-btn-active-border-color: #{rgba($$white, .5)};
    --bs-btn-focus-border-color: #{rgba($$white, .5)};

    // --bs-btn-focus-box-shadow: 0 0 0 .25rem rgba(255, 255, 255, 20%);
  }
}
endef

define DJANGO_FRONTEND_THEME_TOGGLER
document.addEventListener('DOMContentLoaded', function () {
    const rootElement = document.documentElement;
    const anonThemeToggle = document.getElementById('theme-toggler-anonymous');
    const authThemeToggle = document.getElementById('theme-toggler-authenticated');
    if (authThemeToggle) {
        localStorage.removeItem('data-bs-theme');
    }
    const anonSavedTheme = localStorage.getItem('data-bs-theme');
    if (anonSavedTheme) {
        rootElement.setAttribute('data-bs-theme', anonSavedTheme);
    }
    if (anonThemeToggle) {
        anonThemeToggle.addEventListener('click', function () {
            const currentTheme = rootElement.getAttribute('data-bs-theme') || 'light';
            const newTheme = currentTheme === 'light' ? 'dark' : 'light';
            rootElement.setAttribute('data-bs-theme', newTheme);
            localStorage.setItem('data-bs-theme', newTheme);
        });
    }
    if (authThemeToggle) {
        const csrfToken = document.querySelector('[name=csrfmiddlewaretoken]').value;
        authThemeToggle.addEventListener('click', function () {
            const currentTheme = rootElement.getAttribute('data-bs-theme') || 'light';
            const newTheme = currentTheme === 'light' ? 'dark' : 'light';
            fetch('/user/update_theme_preference/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': csrfToken, // Include the CSRF token in the headers
                },
                body: JSON.stringify({ theme: newTheme }),
            })
            .then(response => response.json())
            .then(data => {
                rootElement.setAttribute('data-bs-theme', newTheme);
            })
            .catch(error => {
                console.error('Error updating theme preference:', error);
            });
        });
    }
});
endef

define DJANGO_FRONTEND_TINYMCE_JS
import tinymce from 'tinymce';
import 'tinymce/icons/default';
import 'tinymce/themes/silver';
import 'tinymce/skins/ui/oxide/skin.css';
import 'tinymce/plugins/advlist';
import 'tinymce/plugins/code';
import 'tinymce/plugins/emoticons';
import 'tinymce/plugins/emoticons/js/emojis';
import 'tinymce/plugins/link';
import 'tinymce/plugins/lists';
import 'tinymce/plugins/table';
import 'tinymce/models/dom';

tinymce.init({
  selector: 'textarea#editor',
  plugins: 'advlist code emoticons link lists table',
  toolbar: 'bold italic | bullist numlist | link emoticons',
  skin: false,
  content_css: false,
});
endef

define DJANGO_FRONTEND_USER_MENU
// UserMenu.js
import React from 'react';
import PropTypes from 'prop-types';

function handleLogout() {
    window.location.href = '/accounts/logout';
}

const UserMenu = ({ isAuthenticated, isSuperuser, textColor }) => {
  return (
    <div> 
      {isAuthenticated ? (
        <li className="nav-item dropdown">
          <a className="nav-link dropdown-toggle" type="button" data-bs-toggle="dropdown" aria-expanded="false"></a>
          <ul className="dropdown-menu">
            <li><a className="dropdown-item" href="/user/profile/">Profile</a></li>
            <li><a className="dropdown-item" href="/model-form-demo/">Model Form Demo</a></li>
            <li><a className="dropdown-item" href="/logging-demo/">Logging Demo</a></li>
            <li><a className="dropdown-item" href="/payments/">Payments Demo</a></li>
            {isSuperuser ? (
              <>
                <li><hr className="dropdown-divider"></hr></li>
                <li><a className="dropdown-item" href="/django" target="_blank">Django admin</a></li>
                <li><a className="dropdown-item" href="/api" target="_blank">Django API</a></li>
                <li><a className="dropdown-item" href="/wagtail" target="_blank">Wagtail admin</a></li>
                <li><a className="dropdown-item" href="/explorer" target="_blank">SQL Explorer</a></li>
              </>
            ) : null}
            <li><hr className="dropdown-divider"></hr></li>
            <li><a className="dropdown-item" href="/accounts/logout">Logout</a></li>
          </ul>
        </li>
      ) : (
        <li className="nav-item">
          <a className="nav-link dropdown-toggle" type="button" aria-expanded="false" href="/accounts/login/"></a>
        </li>
      )}
    </div>
  );
};

UserMenu.propTypes = {
  isAuthenticated: PropTypes.bool.isRequired,
  isSuperuser: PropTypes.bool.isRequired,
  textColor: PropTypes.string,
};

export default UserMenu;
endef

# ----------------------------------------------------------------
#  Django Home Page for Django Minimal
#
#  Wagtail projects includes a home page model, Django does not.
# ----------------------------------------------------------------

define DJANGO_HOME_PAGE_ADMIN
from django.contrib import admin  # noqa

# Register your models here.
endef

define DJANGO_HOME_PAGE_MODELS
from django.db import models  # noqa

# Create your models here.
endef

define DJANGO_HOME_PAGE_URLS
from django.urls import path
from .views import HomeView

urlpatterns = [path("", HomeView.as_view(), name="home")]
endef

define DJANGO_HOME_PAGE_VIEWS
from django.views.generic import TemplateView


class HomeView(TemplateView):
    template_name = "home.html"
endef

# ----------------------------------------------------------------
#  Django Logging Demo
# ----------------------------------------------------------------

define DJANGO_LOGGING_DEMO_ADMIN
# Register your models here.
endef

define DJANGO_LOGGING_DEMO_MODELS
from django.db import models  # noqa

# Create your models here.
endef

define DJANGO_LOGGING_DEMO_SETTINGS
INSTALLED_APPS.append("logging_demo")  # noqa
endef

define DJANGO_LOGGING_DEMO_URLS
from django.urls import path
from .views import logging_demo

urlpatterns = [
    path("", logging_demo, name="logging_demo"),
]
endef

define DJANGO_LOGGING_DEMO_VIEWS
from django.http import HttpResponse
import logging

logger = logging.getLogger(__name__)


def logging_demo(request):
    logger.debug("Hello, world!")
    return HttpResponse("Hello, world!")
endef

define DJANGO_MANAGE_PY
#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""

import os
import sys

def main():
    """Run administrative tasks."""
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings.dev")
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
endef

# ----------------------------------------------------------------
#  Django Model Form Demo
# ----------------------------------------------------------------

define DJANGO_MODEL_FORM_DEMO_ADMIN
from django.contrib import admin
from .models import ModelFormDemo


@admin.register(ModelFormDemo)
class ModelFormDemoAdmin(admin.ModelAdmin):
    pass
endef

define DJANGO_MODEL_FORM_DEMO_FORMS
from django import forms
from .models import ModelFormDemo


class ModelFormDemoForm(forms.ModelForm):
    class Meta:
        model = ModelFormDemo
        fields = ["name", "email", "age", "is_active"]
endef

define DJANGO_MODEL_FORM_DEMO_MODELS
from django.db import models
from django.shortcuts import reverse


class ModelFormDemo(models.Model):
    name = models.CharField(max_length=100, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    age = models.IntegerField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name or f"test-model-{self.pk}"

    def get_absolute_url(self):
        return reverse("model_form_demo_detail", kwargs={"pk": self.pk})
endef

define DJANGO_MODEL_FORM_DEMO_TEMPLATE_DETAIL
{% extends 'base.html' %}
{% block content %}
    <h1>Test Model Detail: {{ model_form_demo.name }}</h1>
    <p>Name: {{ model_form_demo.name }}</p>
    <p>Email: {{ model_form_demo.email }}</p>
    <p>Age: {{ model_form_demo.age }}</p>
    <p>Active: {{ model_form_demo.is_active }}</p>
    <p>Created At: {{ model_form_demo.created_at }}</p>
    <a href="{% url 'model_form_demo_update' model_form_demo.pk %}">Edit Test Model</a>
{% endblock %}
endef

define DJANGO_MODEL_FORM_DEMO_TEMPLATE_FORM
{% extends 'base.html' %}
{% block content %}
    <h1>
        {% if form.instance.pk %}
            Update Test Model
        {% else %}
            Create Test Model
        {% endif %}
    </h1>
    <form method="post">
        {% csrf_token %}
        {{ form.as_p }}
        <button type="submit">Save</button>
    </form>
{% endblock %}
endef

define DJANGO_MODEL_FORM_DEMO_TEMPLATE_LIST
{% extends 'base.html' %}
{% block content %}
    <h1>Test Models List</h1>
    <ul>
        {% for model_form_demo in model_form_demos %}
            <li>
                <a href="{% url 'model_form_demo_detail' model_form_demo.pk %}">{{ model_form_demo.name }}</a>
            </li>
        {% endfor %}
    </ul>
    <a href="{% url 'model_form_demo_create' %}">Create New Test Model</a>
{% endblock %}
endef

define DJANGO_MODEL_FORM_DEMO_URLS
from django.urls import path
from .views import (
    ModelFormDemoListView,
    ModelFormDemoCreateView,
    ModelFormDemoUpdateView,
    ModelFormDemoDetailView,
)

urlpatterns = [
    path("", ModelFormDemoListView.as_view(), name="model_form_demo_list"),
    path("create/", ModelFormDemoCreateView.as_view(), name="model_form_demo_create"),
    path(
        "<int:pk>/update/",
        ModelFormDemoUpdateView.as_view(),
        name="model_form_demo_update",
    ),
    path("<int:pk>/", ModelFormDemoDetailView.as_view(), name="model_form_demo_detail"),
]
endef

define DJANGO_MODEL_FORM_DEMO_VIEWS
from django.views.generic import ListView, CreateView, UpdateView, DetailView
from .models import ModelFormDemo
from .forms import ModelFormDemoForm


class ModelFormDemoListView(ListView):
    model = ModelFormDemo
    template_name = "model_form_demo_list.html"
    context_object_name = "model_form_demos"


class ModelFormDemoCreateView(CreateView):
    model = ModelFormDemo
    form_class = ModelFormDemoForm
    template_name = "model_form_demo_form.html"

    def form_valid(self, form):
        form.instance.created_by = self.request.user
        return super().form_valid(form)


class ModelFormDemoUpdateView(UpdateView):
    model = ModelFormDemo
    form_class = ModelFormDemoForm
    template_name = "model_form_demo_form.html"


class ModelFormDemoDetailView(DetailView):
    model = ModelFormDemo
    template_name = "model_form_demo_detail.html"
    context_object_name = "model_form_demo"
endef

define DJANGO_MONGODB_APPS
from django.contrib.admin.apps import AdminConfig
from django.contrib.auth.apps import AuthConfig
from django.contrib.contenttypes.apps import ContentTypesConfig
from allauth.account.apps import AccountConfig


class MongoAdminConfig(AdminConfig):
    default_auto_field = "django_mongodb.fields.ObjectIdAutoField"


class MongoAuthConfig(AuthConfig):
    default_auto_field = "django_mongodb.fields.ObjectIdAutoField"


class MongoContentTypesConfig(ContentTypesConfig):
    default_auto_field = "django_mongodb.fields.ObjectIdAutoField"


class MongoAccountConfig(AccountConfig):
    default_auto_field = "django_mongodb.fields.ObjectIdAutoField"
endef

# ----------------------------------------------------------------
#  Django Payments Demo
# ----------------------------------------------------------------

define DJANGO_PAYMENTS_ADMIN
from django.contrib import admin
from .models import Product, Order

admin.site.register(Product)
admin.site.register(Order)
endef

define DJANGO_PAYMENTS_FORM
from django import forms


class PaymentsForm(forms.Form):
    stripeToken = forms.CharField(widget=forms.HiddenInput())
    amount = forms.DecimalField(
        max_digits=10, decimal_places=2, widget=forms.HiddenInput()
    )
endef

define DJANGO_PAYMENTS_MIGRATION_0002
from django.db import migrations
import os
import secrets
import logging

logger = logging.getLogger(__name__)


def generate_default_key():
    return "sk_test_" + secrets.token_hex(24)


def set_stripe_api_keys(apps, schema_editor):
    # Get the Stripe API Key model
    APIKey = apps.get_model("djstripe", "APIKey")

    # Fetch the keys from environment variables or generate default keys
    test_secret_key = os.environ.get("STRIPE_TEST_SECRET_KEY", generate_default_key())
    live_secret_key = os.environ.get("STRIPE_LIVE_SECRET_KEY", generate_default_key())

    logger.info("STRIPE_TEST_SECRET_KEY: %s", test_secret_key)
    logger.info("STRIPE_LIVE_SECRET_KEY: %s", live_secret_key)

    # Check if the keys are not already in the database
    if not APIKey.objects.filter(secret=test_secret_key).exists():
        APIKey.objects.create(secret=test_secret_key, livemode=False)
        logger.info("Added test secret key to the database.")
    else:
        logger.info("Test secret key already exists in the database.")

    if not APIKey.objects.filter(secret=live_secret_key).exists():
        APIKey.objects.create(secret=live_secret_key, livemode=True)
        logger.info("Added live secret key to the database.")
    else:
        logger.info("Live secret key already exists in the database.")


class Migration(migrations.Migration):

    dependencies = [
        ("payments", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(set_stripe_api_keys),
    ]
endef

define DJANGO_PAYMENTS_MIGRATION_0003
from django.db import migrations


def create_initial_products(apps, schema_editor):
    Product = apps.get_model("payments", "Product")
    Product.objects.create(name="T-shirt", description="A cool T-shirt", price=20.00)
    Product.objects.create(name="Mug", description="A nice mug", price=10.00)
    Product.objects.create(name="Hat", description="A stylish hat", price=15.00)


class Migration(migrations.Migration):
    dependencies = [
        (
            "payments",
            "0002_set_stripe_api_keys",
        ),
    ]

    operations = [
        migrations.RunPython(create_initial_products),
    ]
endef

define DJANGO_PAYMENTS_MODELS
from django.db import models


class Product(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return self.name


class Order(models.Model):
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    stripe_checkout_session_id = models.CharField(max_length=200)

    def __str__(self):
        return f"Order {self.id} for {self.product.name}"
endef

define DJANGO_PAYMENTS_TEMPLATE_CANCEL
{% extends "base.html" %}
{% block title %}Cancel{% endblock %}
{% block content %}
    <h1>Payment Cancelled</h1>
    <p>Your payment was cancelled.</p>
{% endblock %}
endef

define DJANGO_PAYMENTS_TEMPLATE_CHECKOUT
{% extends "base.html" %}
{% block title %}Checkout{% endblock %}
{% block content %}
    <h1>Checkout</h1>
    <form action="{% url 'checkout' %}" method="post">
        {% csrf_token %}
        <button type="submit">Pay</button>
    </form>
{% endblock %}
endef

define DJANGO_PAYMENTS_TEMPLATE_PRODUCT_DETAIL
{% extends "base.html" %}
{% block title %}{{ product.name }}{% endblock %}
{% block content %}
    <h1>{{ product.name }}</h1>
    <p>{{ product.description }}</p>
    <p>Price: ${{ product.price }}</p>
    <form action="{% url 'checkout' %}" method="post">
        {% csrf_token %}
        <input type="hidden" name="product_id" value="{{ product.id }}">
        <button type="submit">Buy Now</button>
    </form>
{% endblock %}
endef

define DJANGO_PAYMENTS_TEMPLATE_PRODUCT_LIST
{% extends "base.html" %}
{% block title %}Products{% endblock %}
{% block content %}
    <h1>Products</h1>
    <ul>
        {% for product in products %}
            <li>
                <a href="{% url 'product_detail' product.pk %}">{{ product.name }} - {{ product.price }}</a>
            </li>
        {% endfor %}
    </ul>
{% endblock %}
endef

define DJANGO_PAYMENTS_TEMPLATE_SUCCESS
{% extends "base.html" %}
{% block title %}Success{% endblock %}
{% block content %}
    <h1>Payment Successful</h1>
    <p>Thank you for your purchase!</p>
{% endblock %}
endef

define DJANGO_PAYMENTS_URLS
from django.urls import path
from .views import (
    CheckoutView,
    SuccessView,
    CancelView,
    ProductListView,
    ProductDetailView,
)

urlpatterns = [
    path("", ProductListView.as_view(), name="product_list"),
    path("product/<int:pk>/", ProductDetailView.as_view(), name="product_detail"),
    path("checkout/", CheckoutView.as_view(), name="checkout"),
    path("success/", SuccessView.as_view(), name="success"),
    path("cancel/", CancelView.as_view(), name="cancel"),
]
endef

define DJANGO_PAYMENTS_VIEW
from django.conf import settings
from django.shortcuts import render, redirect, get_object_or_404
from django.views.generic import TemplateView, View, ListView, DetailView
import stripe
from .models import Product, Order

stripe.api_key = settings.STRIPE_TEST_SECRET_KEY


class ProductListView(ListView):
    model = Product
    template_name = "payments/product_list.html"
    context_object_name = "products"


class ProductDetailView(DetailView):
    model = Product
    template_name = "payments/product_detail.html"
    context_object_name = "product"


class CheckoutView(View):
    template_name = "payments/checkout.html"

    def get(self, request, *args, **kwargs):
        products = Product.objects.all()
        return render(request, self.template_name, {"products": products})

    def post(self, request, *args, **kwargs):
        product_id = request.POST.get("product_id")
        product = get_object_or_404(Product, id=product_id)

        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            line_items=[
                {
                    "price_data": {
                        "currency": "usd",
                        "product_data": {
                            "name": product.name,
                        },
                        "unit_amount": int(product.price * 100),
                    },
                    "quantity": 1,
                }
            ],
            mode="payment",
            success_url="http://localhost:8000/payments/success/",
            cancel_url="http://localhost:8000/payments/cancel/",
        )

        Order.objects.create(product=product, stripe_checkout_session_id=session.id)
        return redirect(session.url, code=303)


class SuccessView(TemplateView):

    template_name = "payments/success.html"


class CancelView(TemplateView):

    template_name = "payments/cancel.html"
endef

# ----------------------------------------------------------------
#  Django Search for Django Minimal
#
#  Wagtail projects includes a search view, Django does not.
# ----------------------------------------------------------------

define DJANGO_SEARCH_FORMS
from django import forms


class SearchForm(forms.Form):
    query = forms.CharField(max_length=100, required=True, label="Search")

endef

define DJANGO_SEARCH_URLS
from django.urls import path
from .views import SearchView

urlpatterns = [
    path("search/", SearchView.as_view(), name="search"),
]
endef

define DJANGO_SEARCH_UTILS
from django.apps import apps
from django.conf import settings

def get_search_models():
    models = []
    for model_path in settings.SEARCH_MODELS:
        app_label, model_name = model_path.split(".")
        model = apps.get_model(app_label, model_name)
        models.append(model)
    return models
endef

define DJANGO_SEARCH_VIEWS
from django.views.generic import ListView
from django.db import models
from django.db.models import Q 
from .forms import SearchForm
from .utils import get_search_models


class SearchView(ListView):
    template_name = "your_app/search_results.html"
    context_object_name = "results"
    paginate_by = 10

    def get_queryset(self):
        form = SearchForm(self.request.GET)
        query = None
        results = []

        if form.is_valid():
            query = form.cleaned_data["query"]
            search_models = get_search_models()

            for model in search_models:
                fields = [f.name for f in model._meta.fields if isinstance(f, (models.CharField, models.TextField))]
                queries = [Q(**{f"{field}__icontains": query}) for field in fields]
                model_results = model.objects.filter(queries.pop())

                for item in queries:
                    model_results = model_results.filter(item)

                results.extend(model_results)

        return results

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["form"] = SearchForm(self.request.GET)
        context["query"] = self.request.GET.get("query", "")
        return context
endef

# ----------------------------------------------------------------
#  Django Settings
# ----------------------------------------------------------------

define DJANGO_SETTINGS_AUTHENTICATION_BACKENDS
AUTHENTICATION_BACKENDS = [
    "django.contrib.auth.backends.ModelBackend",
    "allauth.account.auth_backends.AuthenticationBackend",
]
endef

define DJANGO_SETTINGS_BASE
# $(PROJECT_NAME)
#
# Uncomment next two lines to enable custom admin
# INSTALLED_APPS = [app for app in INSTALLED_APPS if app != 'django.contrib.admin']
# INSTALLED_APPS.append('backend.apps.CustomAdminConfig')
import os  # noqa
import dj_database_url  # noqa

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
EXPLORER_CONNECTIONS = {"Default": "default"}
EXPLORER_DEFAULT_CONNECTION = "default"
LOGIN_REDIRECT_URL = "/"
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SILENCED_SYSTEM_CHECKS = ["django_recaptcha.recaptcha_test_key_error"]
BASE_DIR = os.path.dirname(PROJECT_DIR)
STATICFILES_DIRS = []
WEBPACK_LOADER = {
    "MANIFEST_FILE": os.path.join(BASE_DIR, "frontend/build/manifest.json"),
}
STATICFILES_DIRS.append(os.path.join(BASE_DIR, "frontend/build"))
TEMPLATES[0]["DIRS"].append(os.path.join(PROJECT_DIR, "templates"))
THEMES = [
    ("light", "Light Theme"),
    ("dark", "Dark Theme"),
]
endef

define DJANGO_SETTINGS_CRISPY_FORMS
CRISPY_TEMPLATE_PACK = "bootstrap5"
CRISPY_ALLOWED_TEMPLATE_PACKS = "bootstrap5"
endef

define DJANGO_SETTINGS_DATABASE
DATABASE_URL = os.environ.get("DATABASE_URL", "postgres://:@:/$(PACKAGE_NAME)")
DATABASES["default"] = dj_database_url.parse(DATABASE_URL)
endef

define DJANGO_SETTINGS_DEV
from .base import *  # noqa

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

# SECURITY WARNING: define the correct hosts in production!
ALLOWED_HOSTS = ["*"]

EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

try:
    from .local import *  # noqa
except ImportError:
    pass

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {message}",
            "style": "{",
        },
        "simple": {
            "format": "{levelname} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "level": "DEBUG",
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "DEBUG",
            "propagate": True,
        },
    },
}

INTERNAL_IPS = [
    "127.0.0.1",
]

MIDDLEWARE.append("debug_toolbar.middleware.DebugToolbarMiddleware")  # noqa
MIDDLEWARE.append("hijack.middleware.HijackUserMiddleware")  # noqa
INSTALLED_APPS.append("django.contrib.admindocs")  # noqa
SECRET_KEY = "$(DJANGO_SETTINGS_SECRET_KEY)"
endef


define DJANGO_SETTINGS_HOME_PAGE
INSTALLED_APPS.append("home")
endef

define DJANGO_SETTINGS_INSTALLED_APPS
INSTALLED_APPS.append("allauth")
INSTALLED_APPS.append("allauth.account")
INSTALLED_APPS.append("allauth.socialaccount")
INSTALLED_APPS.append("crispy_bootstrap5")
INSTALLED_APPS.append("crispy_forms")
INSTALLED_APPS.append("debug_toolbar")
INSTALLED_APPS.append("django_extensions")
INSTALLED_APPS.append("django_recaptcha")
INSTALLED_APPS.append("rest_framework")
INSTALLED_APPS.append("rest_framework.authtoken")
INSTALLED_APPS.append("webpack_boilerplate")
INSTALLED_APPS.append("explorer")
endef

define DJANGO_SETTINGS_MIDDLEWARE
MIDDLEWARE.append("allauth.account.middleware.AccountMiddleware")
endef

define DJANGO_SETTINGS_MODEL_FORM_DEMO
INSTALLED_APPS.append("model_form_demo")  # noqa
endef

define DJANGO_SETTINGS_MONGODB
DATABASES = {
    'default': {
	'ENGINE': 'django_mongodb',
	'NAME': 'test',
    }
}
DJANGO_COMPAT_CHECK_DISABLED = True
DEFAULT_AUTO_FIELD = "django_mongodb.fields.ObjectIdAutoField"
MIGRATION_MODULES = {
    "account": "backend.migrations.account",
    "admin": "backend.migrations.admin",
    "auth": "backend.migrations.auth",
    "contenttypes": "backend.migrations.contenttypes",
}
INSTALLED_APPS.remove("allauth.account")
INSTALLED_APPS.remove("django.contrib.admin")
INSTALLED_APPS.remove("django.contrib.auth")
INSTALLED_APPS.remove("django.contrib.contenttypes")
INSTALLED_APPS.append("backend.apps.MongoAccountConfig")
INSTALLED_APPS.append("backend.apps.MongoAdminConfig")
INSTALLED_APPS.append("backend.apps.MongoAuthConfig")
INSTALLED_APPS.append("backend.apps.MongoContentTypesConfig")
endef

define DJANGO_SETTINGS_PAYMENTS
DJSTRIPE_FOREIGN_KEY_TO_FIELD = "id"
DJSTRIPE_WEBHOOK_VALIDATION = "retrieve_event"
STRIPE_PUBLISHABLE_KEY = os.environ.get("STRIPE_PUBLISHABLE_KEY")
STRIPE_SECRET_KEY = os.environ.get("STRIPE_SECRET_KEY")
STRIPE_TEST_SECRET_KEY = os.environ.get("STRIPE_TEST_SECRET_KEY")
INSTALLED_APPS.append("payments")  # noqa
INSTALLED_APPS.append("djstripe")  # noqa
endef

define DJANGO_SETTINGS_PROD
from .base import *  # noqa
from backend.utils import get_ec2_metadata

DEBUG = False

try:
    from .local import *  # noqa
except ImportError:
    pass

LOCAL_IPV4 = get_ec2_metadata()
ALLOWED_HOSTS.append(LOCAL_IPV4)  # noqa
endef

define DJANGO_SETTINGS_REST_FRAMEWORK
REST_FRAMEWORK = {
    # Use Django's standard `django.contrib.auth` permissions,
    # or allow read-only access for unauthenticated users.
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.DjangoModelPermissionsOrAnonReadOnly"
    ]
}
endef

define DJANGO_SETTINGS_SEARCH
INSTALLED_APPS.append("search")  # noqa
endef

define DJANGO_SETTINGS_SITEUSER
INSTALLED_APPS.append("siteuser")  # noqa
AUTH_USER_MODEL = "siteuser.User"
endef

define DJANGO_SETTINGS_UNIT_TEST_DEMO
INSTALLED_APPS.append("unit_test_demo")  # noqa
endef

# ----------------------------------------------------------------
#  Django SiteUser
#
#  A custom user model for Django
#
#  https://docs.djangoproject.com/en/5.1/topics/auth/customizing/#using-a-custom-user-model-when-starting-a-project
# ----------------------------------------------------------------

define DJANGO_SITEUSER_ADMIN
from django.contrib.auth.admin import UserAdmin
from django.contrib import admin

from .models import User

admin.site.register(User, UserAdmin)
endef

define DJANGO_SITEUSER_FORM
from django import forms
from django.contrib.auth.forms import UserChangeForm
from crispy_forms.helper import FormHelper
from crispy_forms.layout import Layout, Fieldset, ButtonHolder, Submit
from .models import User


class SiteUserForm(UserChangeForm):
    bio = forms.CharField(widget=forms.Textarea(attrs={"id": "editor"}), required=False)

    class Meta(UserChangeForm.Meta):
        model = User
        fields = ("username", "user_theme_preference", "bio", "rate")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.form_method = "post"
        self.helper.layout = Layout(
            Fieldset(
                "Edit Your Profile",
                "username",
                "user_theme_preference",
                "bio",
                "rate",
            ),
            ButtonHolder(Submit("submit", "Save", css_class="btn btn-primary")),
        )
endef

define DJANGO_SITEUSER_MODEL
from django.db import models
from django.contrib.auth.models import AbstractUser, Group, Permission
from django.conf import settings


class User(AbstractUser):
    groups = models.ManyToManyField(Group, related_name="siteuser_set", blank=True)
    user_permissions = models.ManyToManyField(
        Permission, related_name="siteuser_set", blank=True
    )

    user_theme_preference = models.CharField(
        max_length=10, choices=settings.THEMES, default="light"
    )

    bio = models.TextField(blank=True, null=True)
    rate = models.FloatField(blank=True, null=True)
endef

define DJANGO_SITEUSER_URLS
from django.urls import path
from .views import UserProfileView, UpdateThemePreferenceView, UserEditView

urlpatterns = [
    path("profile/", UserProfileView.as_view(), name="user-profile"),
    path(
        "update_theme_preference/",
        UpdateThemePreferenceView.as_view(),
        name="update_theme_preference",
    ),
    path("<int:pk>/edit/", UserEditView.as_view(), name="user-edit"),
]
endef

define DJANGO_SITEUSER_VIEW
import json

from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import JsonResponse
from django.utils.decorators import method_decorator
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from django.views.generic import DetailView
from django.views.generic.edit import UpdateView
from django.urls import reverse_lazy

from .models import User
from .forms import SiteUserForm


class UserProfileView(LoginRequiredMixin, DetailView):
    model = User
    template_name = "user.html"

    def get_object(self, queryset=None):
        return self.request.user


@method_decorator(csrf_exempt, name="dispatch")
class UpdateThemePreferenceView(View):
    def post(self, request, *args, **kwargs):
        try:
            data = json.loads(request.body.decode("utf-8"))
            new_theme = data.get("theme")
            user = request.user
            user.user_theme_preference = new_theme
            user.save()
            response_data = {"theme": new_theme}
            return JsonResponse(response_data)
        except json.JSONDecodeError as e:
            return JsonResponse({"error": e}, status=400)

    def http_method_not_allowed(self, request, *args, **kwargs):
        return JsonResponse({"error": "Invalid request method"}, status=405)


class UserEditView(LoginRequiredMixin, UpdateView):
    model = User
    template_name = "user_edit.html"  # Create this template in your templates folder
    form_class = SiteUserForm

    def get_success_url(self):
        # return reverse_lazy("user-profile", kwargs={"pk": self.object.pk})
        return reverse_lazy("user-profile")
endef

# ----------------------------------------------------------------
#  Django Templates
# ----------------------------------------------------------------

define DJANGO_TEMPLATE_ALLAUTH
{% extends 'base.html' %}
endef

define DJANGO_TEMPLATE_BASE
{% load static webpack_loader %}
<!DOCTYPE html>
<html lang="en"
      class="h-100"
      data-bs-theme="{{ request.user.user_theme_preference|default:'light' }}">
    <head>
        <meta charset="utf-8" />
        <title>
            {% block title %}{% endblock %}
            {% block title_suffix %}{% endblock %}
        </title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        {% stylesheet_pack 'app' %}
        {% block extra_css %}{# Override this in templates to add extra stylesheets #}{% endblock %}
        <style>
            .success {
                background-color: #d4edda;
                border-color: #c3e6cb;
                color: #155724;
            }

            .info {
                background-color: #d1ecf1;
                border-color: #bee5eb;
                color: #0c5460;
            }

            .warning {
                background-color: #fff3cd;
                border-color: #ffeeba;
                color: #856404;
            }

            .danger {
                background-color: #f8d7da;
                border-color: #f5c6cb;
                color: #721c24;
            }
        </style>
        {% include 'favicon.html' %}
        {% csrf_token %}
    </head>
    <body class="{% block body_class %}{% endblock %} d-flex flex-column h-100">
        <main class="flex-shrink-0">
            <div id="app"></div>
            {% include 'header.html' %}
            {% if messages %}
                <div class="messages container">
                    {% for message in messages %}
                        <div class="alert {{ message.tags }} alert-dismissible fade show"
                             role="alert">
                            {{ message }}
                            <button type="button"
                                    class="btn-close"
                                    data-bs-dismiss="alert"
                                    aria-label="Close"></button>
                        </div>
                    {% endfor %}
                </div>
            {% endif %}
            <div class="container">
                {% block content %}{% endblock %}
            </div>
        </main>
        {% include 'footer.html' %}
        {% include 'offcanvas.html' %}
        {% javascript_pack 'app' %}
        {% block extra_js %}{# Override this in templates to add extra javascript #}{% endblock %}
    </body>
</html>
endef

define DJANGO_TEMPLATE_FAVICON
{% load static %}
<link href="{% static 'wagtailadmin/images/favicon.ico' %}" rel="icon">
endef

define DJANGO_TEMPLATE_FOOTER
<footer class="footer mt-auto py-3 bg-body-tertiary pt-5 text-center text-small">
    <p class="mb-1">&copy; {% now "Y" %} {{ current_site.site_name|default:"Project Makefile" }}</p>
    <ul class="list-inline">
        <li class="list-inline-item">
            <a class="text-secondary text-decoration-none {% if request.path == '/' %}active{% endif %}"
               href="/">Home</a>
        </li>
        {% for child in current_site.root_page.get_children %}
            <li class="list-inline-item">
                <a class="text-secondary text-decoration-none {% if request.path == child.url %}active{% endif %}"
                   href="{{ child.url }}">{{ child }}</a>
            </li>
        {% endfor %}
    </ul>
</footer>
endef

define DJANGO_TEMPLATE_HEADER
<div class="app-header">
    <div class="container py-4 app-navbar">
        <nav class="navbar navbar-transparent navbar-padded navbar-expand-md">
            <a class="navbar-brand me-auto" href="/">{{ current_site.site_name|default:"Project Makefile" }}</a>
            <button class="navbar-toggler"
                    type="button"
                    data-bs-toggle="offcanvas"
                    data-bs-target="#offcanvasExample"
                    aria-controls="offcanvasExample"
                    aria-expanded="false"
                    aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="d-none d-md-block">
                <ul class="navbar-nav">
                    <li class="nav-item">
                        <a id="home-nav"
                           class="nav-link {% if request.path == '/' %}active{% endif %}"
                           aria-current="page"
                           href="/">Home</a>
                    </li>
                    {% for child in current_site.root_page.get_children %}
                        {% if child.show_in_menus %}
                            <li class="nav-item">
                                <a class="nav-link {% if request.path == child.url %}active{% endif %}"
                                   aria-current="page"
                                   href="{{ child.url }}">{{ child }}</a>
                            </li>
                        {% endif %}
                    {% endfor %}
                    <div data-component="UserMenu"
                         data-is-authenticated="{{ request.user.is_authenticated }}"
                         data-is-superuser="{{ request.user.is_superuser }}"></div>
                    <li class="nav-item"
                        id="{% if request.user.is_authenticated %}theme-toggler-authenticated{% else %}theme-toggler-anonymous{% endif %}">
                        <span class="nav-link" data-bs-toggle="tooltip" title="Toggle dark mode">
                            <i class="fas fa-circle-half-stroke"></i>
                        </span>
                    </li>
                    <li class="nav-item">
                        <form class="form" action="/search">
                            <div class="row">
                                <div class="col-8">
                                    <input class="form-control"
                                           type="search"
                                           name="query"
                                           {% if search_query %}value="{{ search_query }}"{% endif %}>
                                </div>
                                <div class="col-4">
                                    <input type="submit" value="Search" class="form-control">
                                </div>
                            </div>
                        </form>
                    </li>
                </ul>
            </div>
        </nav>
    </div>
</div>
endef 

define DJANGO_TEMPLATE_HOME_PAGE
{% extends "base.html" %}
{% block content %}
    <main class="{% block main_class %}{% endblock %}">
    </main>
{% endblock %}
endef

define DJANGO_TEMPLATE_OFFCANVAS
<div class="offcanvas offcanvas-start bg-dark"
     tabindex="-1"
     id="offcanvasExample"
     aria-labelledby="offcanvasExampleLabel">
    <div class="offcanvas-header">
        <a class="offcanvas-title text-light h5 text-decoration-none"
           id="offcanvasExampleLabel"
           href="/">{{ current_site.site_name|default:"Project Makefile" }}</a>
        <button type="button"
                class="btn-close bg-light"
                data-bs-dismiss="offcanvas"
                aria-label="Close"></button>
    </div>
    <div class="offcanvas-body bg-dark">
        <ul class="navbar-nav justify-content-end flex-grow-1 pe-3">
            <li class="nav-item">
                <a class="nav-link text-light active" aria-current="page" href="/">Home</a>
            </li>
            {% for child in current_site.root_page.get_children %}
                <li class="nav-item">
                    <a class="nav-link text-light" href="{{ child.url }}">{{ child }}</a>
                </li>
            {% endfor %}
            <li class="nav-item"
                id="{% if request.user.is_authenticated %}theme-toggler-authenticated{% else %}theme-toggler-anonymous{% endif %}">
                <span class="nav-link text-light"
                      data-bs-toggle="tooltip"
                      title="Toggle dark mode">
                    <i class="fas fa-circle-half-stroke"></i>
                </span>
            </li>
            <div data-component="UserMenu"
                 data-text-color="light"
                 data-is-authenticated="{{ request.user.is_authenticated }}"
                 data-is-superuser="{{ request.user.is_superuser }}"></div>
        </ul>
    </div>
</div>
endef

define DJANGO_TEMPLATE_SEARCH
{% extends 'base.html' %}
{% block content %}
    <h1>Search Results</h1>
    <form method="get">
	{{ form.as_p }}
	<button type="submit">Search</button>
    </form>
    <ul>
	{% for result in results %}
	    <li>{{ result }}</li>
	{% endfor %}
    </ul>
{% endblock %}
endef

define DJANGO_TEMPLATE_SITEUSER_EDIT
{% extends 'base.html' %}
{% load crispy_forms_tags %}
{% block content %}
    <h2>Edit User</h2>
    {% crispy form %}
{% endblock %}
endef

define DJANGO_TEMPLATE_SITEUSER_VIEW
{% extends 'base.html' %}
{% block content %}
    <h2>User Profile</h2>
    <div class="d-flex justify-content-end">
        <a class="btn btn-outline-secondary"
           href="{% url 'user-edit' pk=user.id %}">Edit</a>
    </div>
    <p>Username: {{ user.username }}</p>
    <p>Theme: {{ user.user_theme_preference }}</p>
    <p>Bio: {{ user.bio|default:""|safe }}</p>
    <p>Rate: {{ user.rate|default:"" }}</p>
{% endblock %}
endef

# ----------------------------------------------------------------
#  Django Unit Test Demo
# ----------------------------------------------------------------

define DJANGO_UNIT_TEST_DEMO_FORMS
from django import forms
from .models import UnitTestDemoModel

class UnitTestDemoForm(forms.ModelForm):
    class Meta:
        model = UnitTestDemoModel
        fields = ["field1", "field2"]
endef

define DJANGO_UNIT_TEST_DEMO_MODELS
from django.db import models

class UnitTestDemoModel(models.Model):
    field1 = models.CharField(max_length=100)
    field2 = models.CharField(max_length=100)

    def __str__(self):
        return "Expected String Representation"
endef

define DJANGO_UNIT_TEST_DEMO_TESTS
from django.test import TestCase  # noqa
from django.urls import reverse  # noqa
from .models import UnitTestDemoModel
from .forms import UnitTestDemoForm


class UnitTestDemoModelTest(TestCase):
     def setUp(self):
         self.instance = UnitTestDemoModel.objects.create(field1="value1", field2="value2")
 
     def test_instance_creation(self):
         self.assertIsInstance(self.instance, UnitTestDemoModel)
         self.assertEqual(self.instance.field1, "value1")
         self.assertEqual(self.instance.field2, "value2")
 
     def test_str_method(self):
         self.assertEqual(str(self.instance), "Expected String Representation")
 
 
class UnitTestDemoViewTest(TestCase):
     def setUp(self):
         self.instance = UnitTestDemoModel.objects.create(field1="value1", field2="value2")
 
     def test_view_url_exists_at_desired_location(self):
         response = self.client.get("/unit-test-demo-url/")
         self.assertEqual(response.status_code, 200)
 
     def test_view_url_accessible_by_name(self):
         response = self.client.get(reverse("unit-test-demo-view-name"))
         self.assertEqual(response.status_code, 200)
 
     def test_view_uses_correct_template(self):
         response = self.client.get(reverse("unit-test-demo-view-name"))
         self.assertEqual(response.status_code, 200)
         self.assertTemplateUsed(response, "unit-test-demo.html")
 
     def test_view_context(self):
         response = self.client.get(reverse("unit-test-demo-view-name"))
         self.assertEqual(response.status_code, 200)
         self.assertIn("context_variable", response.context)
 
 
class UnitTestDemoFormTest(TestCase):

     def test_form_valid_data(self):
         form = UnitTestDemoForm(data={"field1": "value1", "field2": "value2"})
         self.assertTrue(form.is_valid())
 
     def test_form_invalid_data(self):
         form = UnitTestDemoForm(data={"field1": "", "field2": "value2"})
         self.assertFalse(form.is_valid())
         self.assertIn("field1", form.errors)
 
     def test_form_save(self):
         form = UnitTestDemoForm(data={"field1": "value1", "field2": "value2"})
         if form.is_valid():
             instance = form.save()
             self.assertEqual(instance.field1, "value1")
             self.assertEqual(instance.field2, "value2")
endef

# ----------------------------------------------------------------
#  Django URLs
# ----------------------------------------------------------------

define DJANGO_URLS
from django.contrib import admin
from django.urls import path, include
from django.conf import settings

urlpatterns = [
    path("django/", admin.site.urls),
]
endef

define DJANGO_URLS_ALLAUTH
urlpatterns += [path("accounts/", include("allauth.urls"))]
endef

define DJANGO_URLS_API
from rest_framework import routers  # noqa
from .api import UserViewSet, api  # noqa

router = routers.DefaultRouter()
router.register(r"users", UserViewSet)
# urlpatterns += [path("api/", include(router.urls))]
urlpatterns += [path("api/", api.urls)]
endef

define DJANGO_URLS_DEBUG_TOOLBAR
if settings.DEBUG:
    urlpatterns += [path("__debug__/", include("debug_toolbar.urls"))]
endef

define DJANGO_URLS_HOME_PAGE
urlpatterns += [path("", include("home.urls"))]
endef

define DJANGO_URLS_LOGGING_DEMO
urlpatterns += [path("logging-demo/", include("logging_demo.urls"))]
endef

define DJANGO_URLS_MODEL_FORM_DEMO
urlpatterns += [path("model-form-demo/", include("model_form_demo.urls"))]
endef

define DJANGO_URLS_PAYMENTS
urlpatterns += [path("payments/", include("payments.urls"))]
endef

define DJANGO_URLS_SITEUSER
urlpatterns += [path("user/", include("siteuser.urls"))]
endef

define DJANGO_UTILS
from django.urls import URLResolver
import requests


def get_ec2_metadata():
    try:
        # Step 1: Get the token
        token_url = "http://169.254.169.254/latest/api/token"
        headers = {"X-aws-ec2-metadata-token-ttl-seconds": "21600"}
        response = requests.put(token_url, headers=headers)
        response.raise_for_status()  # Raise an error for bad responses

        token = response.text

        # Step 2: Use the token to get the instance metadata
        metadata_url = "http://169.254.169.254/latest/meta-data/local-ipv4"
        headers = {"X-aws-ec2-metadata-token": token}
        response = requests.get(metadata_url, headers=headers)
        response.raise_for_status()  # Raise an error for bad responses

        metadata = response.text
        return metadata
    except requests.RequestException as e:
        print(f"Error retrieving EC2 metadata: {e}")
        return None


# Function to remove a specific URL pattern based on its route (including catch-all)
def remove_urlpattern(urlpatterns, route_to_remove):
    urlpatterns[:] = [
        urlpattern
        for urlpattern in urlpatterns
        if not (
            isinstance(urlpattern, URLResolver)
            and urlpattern.pattern._route == route_to_remove
        )
    ]
endef

define EB_CUSTOM_ENV_EC2_USER
files:
    "/home/ec2-user/.bashrc":
        mode: "000644"
        owner: ec2-user
        group: ec2-user
        content: |
            # .bashrc

            # Source global definitions
            if [ -f /etc/bashrc ]; then
                    . /etc/bashrc
            fi

            # User specific aliases and functions
            set -o vi

            source <(sed -E -n 's/[^#]+/export &/ p' /opt/elasticbeanstalk/deployment/custom_env_var)
endef

define EB_CUSTOM_ENV_VAR_FILE
#!/bin/bash

# Via https://aws.amazon.com/premiumsupport/knowledge-center/elastic-beanstalk-env-variables-linux2/

#Create a copy of the environment variable file.
cat /opt/elasticbeanstalk/deployment/env | perl -p -e 's/(.*)=(.*)/export $$1="$$2"/;' > /opt/elasticbeanstalk/deployment/custom_env_var

#Set permissions to the custom_env_var file so this file can be accessed by any user on the instance. You can restrict permissions as per your requirements.
chmod 644 /opt/elasticbeanstalk/deployment/custom_env_var

# add the virtual env path in.
VENV=/var/app/venv/`ls /var/app/venv`
cat <<EOF >> /opt/elasticbeanstalk/deployment/custom_env_var
VENV=$$ENV
EOF

#Remove duplicate files upon deployment.
rm -f /opt/elasticbeanstalk/deployment/*.bak
endef

define EB_DJANGO_DATABASE
$(shell echo $(EB_DJANGO_DATABASE_URL) | python -c 'import dj_database_url; url = input(); url = dj_database_url.parse(url); print(url["$1"])')
endef

define GIT_COMMIT_IGNORE
__pycache__
*.pyc
dist/
node_modules/
_build/
.elasticbeanstalk/
db.sqlite3
static/
backend/inituser
backend/var
.venv/
endef

define GIT_COMMIT_MESSAGE
$(1)
endef

define JENKINS_FILE
pipeline {
    agent any
    stages {
        stage('') {
            steps {
                echo ''
            }
        }
    }
}
endef

define PIP_INSTALL_REQUIREMENTS_TEST
pytest
pytest-runner
coverage
pytest-mock
pytest-cov
hypothesis
selenium
pytest-django
factory-boy
flake8
tox
endef

define PROJECT_CUSTOM
# Custom Makefile for Project Makefile
# Add your custom Makefile commands here
#
# PROJECT_NAME := my-new-project
endef

define LICENSE_TXT
MIT License

Copyright (c) [YEAR] [OWNER NAME]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
endef

define PYTHON_PROJECT_TOML
[build-system]
endef

define SEPARATOR
.======================================================================
|                                                                      |
| _|_|_|                        _|                        _|           |
| _|    _|  _|  _|_|    _|_|          _|_|      _|_|_|  _|_|_|_|       |
| _|_|_|    _|_|      _|    _|  _|  _|_|_|_|  _|          _|           |
| _|        _|        _|    _|  _|  _|        _|          _|           |
| _|        _|          _|_|    _|    _|_|_|    _|_|_|      _|_|       |
|                               _|                                     |
|                             _|                                       |
|                                                                      |
 ---------------------------------------------------------------------- 
|                                                                      |  
| _|      _|            _|                      _|_|  _|  _|           | 
| _|_|  _|_|    _|_|_|  _|  _|      _|_|      _|          _|    _|_|   |
| _|  _|  _|  _|    _|  _|_|      _|_|_|_|  _|_|_|_|  _|  _|  _|_|_|_| |
| _|      _|  _|    _|  _|  _|    _|          _|      _|  _|  _|       |
| _|      _|    _|_|_|  _|    _|    _|_|_|    _|      _|  _|    _|_|_| |
|                                                                      |
|                                                                      |
 ======================================================================'
endef

define WAGTAIL_BLOCK_CAROUSEL
<div id="carouselExampleCaptions" class="carousel slide">
    <div class="carousel-indicators">
        {% for image in block.value.images %}
            <button type="button"
                    data-bs-target="#carouselExampleCaptions"
                    data-bs-slide-to="{{ forloop.counter0 }}"
                    {% if forloop.first %}class="active" aria-current="true"{% endif %}
                    aria-label="Slide {{ forloop.counter }}"></button>
        {% endfor %}
    </div>
    <div class="carousel-inner">
        {% for image in block.value.images %}
            <div class="carousel-item {% if forloop.first %}active{% endif %}">
                <img src="{{ image.file.url }}" class="d-block w-100" alt="...">
                <div class="carousel-caption d-none d-md-block">
                    <h5>{{ image.title }}</h5>
                </div>
            </div>
        {% endfor %}
    </div>
    <button class="carousel-control-prev"
            type="button"
            data-bs-target="#carouselExampleCaptions"
            data-bs-slide="prev">
        <span class="carousel-control-prev-icon" aria-hidden="true"></span>
        <span class="visually-hidden">Previous</span>
    </button>
    <button class="carousel-control-next"
            type="button"
            data-bs-target="#carouselExampleCaptions"
            data-bs-slide="next">
        <span class="carousel-control-next-icon" aria-hidden="true"></span>
        <span class="visually-hidden">Next</span>
    </button>
</div>
endef

define WAGTAIL_BLOCK_MARKETING
{% load wagtailcore_tags %}
<div class="{{ self.block_class }}">
    {% if block.value.images.0 %}
        {% include 'blocks/carousel_block.html' %}
    {% else %}
        {{ self.title }}
        {{ self.content }}
    {% endif %}
</div>
endef

define WAGTAIL_CONTACT_PAGE_MODEL
from django.db import models
from modelcluster.fields import ParentalKey
from wagtail.admin.panels import (
    FieldPanel, FieldRowPanel,
    InlinePanel, MultiFieldPanel
)
from wagtail.fields import RichTextField
from wagtail.contrib.forms.models import AbstractEmailForm, AbstractFormField


class FormField(AbstractFormField):
    page = ParentalKey('ContactPage', on_delete=models.CASCADE, related_name='form_fields')


class ContactPage(AbstractEmailForm):
    intro = RichTextField(blank=True)
    thank_you_text = RichTextField(blank=True)

    content_panels = AbstractEmailForm.content_panels + [
        FieldPanel('intro'),
        InlinePanel('form_fields', label="Form fields"),
        FieldPanel('thank_you_text'),
        MultiFieldPanel([
            FieldRowPanel([
                FieldPanel('from_address', classname="col6"),
                FieldPanel('to_address', classname="col6"),
            ]),
            FieldPanel('subject'),
        ], "Email"),
    ]

    class Meta:
        verbose_name = "Contact Page"
endef

define WAGTAIL_CONTACT_PAGE_TESTS
from django.test import TestCase
from wagtail.test.utils import WagtailPageTestCase
from wagtail.models import Page

from contactpage.models import ContactPage, FormField

class ContactPageTest(TestCase, WagtailPageTestCase):
    def test_contact_page_creation(self):
        # Create a ContactPage instance
        contact_page = ContactPage(
            title='Contact',
            intro='Welcome to our contact page!',
            thank_you_text='Thank you for reaching out.'
        )

        # Save the ContactPage instance
        self.assertEqual(contact_page.save_revision().publish().get_latest_revision_as_page(), contact_page)

    def test_form_field_creation(self):
        # Create a ContactPage instance
        contact_page = ContactPage(
            title='Contact',
            intro='Welcome to our contact page!',
            thank_you_text='Thank you for reaching out.'
        )
        # Save the ContactPage instance
        contact_page_revision = contact_page.save_revision()
        contact_page_revision.publish()

        # Create a FormField associated with the ContactPage
        form_field = FormField(
            page=contact_page,
            label='Your Name',
            field_type='singleline',
            required=True
        )
        form_field.save()

        # Retrieve the ContactPage from the database
        contact_page_from_db = Page.objects.get(id=contact_page.id).specific

        # Check if the FormField is associated with the ContactPage
        self.assertEqual(contact_page_from_db.form_fields.first(), form_field)

    def test_contact_page_form_submission(self):
        # Create a ContactPage instance
        contact_page = ContactPage(
            title='Contact',
            intro='Welcome to our contact page!',
            thank_you_text='Thank you for reaching out.'
        )
        # Save the ContactPage instance
        contact_page_revision = contact_page.save_revision()
        contact_page_revision.publish()

        # Simulate a form submission
        form_data = {
            'your_name': 'John Doe',
            # Add other form fields as needed
        }

        response = self.client.post(contact_page.url, form_data)

        # Check if the form submission is successful (assuming a 302 redirect)
        self.assertEqual(response.status_code, 302)
        
        # You may add more assertions based on your specific requirements
endef

define WAGTAIL_HEADER_PREFIX
{% load wagtailcore_tags %}
{% wagtail_site as current_site %}
endef 

define WAGTAIL_HOME_PAGE_MODEL
from wagtail.models import Page
from wagtail.fields import StreamField
from wagtail import blocks
from wagtail.admin.panels import FieldPanel
from wagtail.images.blocks import ImageChooserBlock


class MarketingBlock(blocks.StructBlock):
    title = blocks.CharBlock(required=False, help_text="Enter the block title")
    content = blocks.RichTextBlock(required=False, help_text="Enter the block content")
    images = blocks.ListBlock(
        ImageChooserBlock(required=False),
        help_text="Select one or two images for column display. Select three or more images for carousel display.",
    )
    image = ImageChooserBlock(
        required=False, help_text="Select one image for background display."
    )
    block_class = blocks.CharBlock(
        required=False,
        help_text="Enter a CSS class for styling the marketing block",
        classname="full title",
        default="vh-100 bg-secondary",
    )
    image_class = blocks.CharBlock(
        required=False,
        help_text="Enter a CSS class for styling the column display image(s)",
        classname="full title",
        default="img-thumbnail p-5",
    )
    layout_class = blocks.CharBlock(
        required=False,
        help_text="Enter a CSS class for styling the layout.",
        classname="full title",
        default="d-flex flex-row",
    )

    class Meta:
        icon = "placeholder"
        template = "blocks/marketing_block.html"


class HomePage(Page):

    template = "home/home_page.html"  # Create a template for rendering the home page

    marketing_blocks = StreamField(
        [
            ("marketing_block", MarketingBlock()),
        ],
        blank=True,
        null=True,
        use_json_field=True,
    )
    content_panels = Page.content_panels + [
        FieldPanel("marketing_blocks"),
    ]

    class Meta:
        verbose_name = "Home Page"
endef

define WAGTAIL_PRIVACY_PAGE_MODEL
from wagtail.models import Page
from wagtail.admin.panels import FieldPanel
from wagtailmarkdown.fields import MarkdownField


class PrivacyPage(Page):
    """
    A Wagtail Page model for the Privacy Policy page.
    """

    template = "privacy_page.html"

    body = MarkdownField()

    content_panels = Page.content_panels + [
        FieldPanel("body", classname="full"),
    ]

    class Meta:
        verbose_name = "Privacy Page"
endef

define WAGTAIL_SEARCH_URLS
from django.urls import path
from .views import search

urlpatterns = [path("", search, name="search")]
endef

define WAGTAIL_SETTINGS
INSTALLED_APPS.append("wagtail_color_panel")
INSTALLED_APPS.append("wagtail_modeladmin")
INSTALLED_APPS.append("wagtail.contrib.settings")
INSTALLED_APPS.append("wagtailmarkdown")
INSTALLED_APPS.append("wagtailmenus")
INSTALLED_APPS.append("wagtailseo")
TEMPLATES[0]["OPTIONS"]["context_processors"].append(
    "wagtail.contrib.settings.context_processors.settings"
)
TEMPLATES[0]["OPTIONS"]["context_processors"].append(
    "wagtailmenus.context_processors.wagtailmenus"
)
endef

define WAGTAIL_SETTINGS_CONTACT_PAGE
INSTALLED_APPS.append("contactpage")  # noqa
endef

define WAGTAIL_SETTINGS_PRIVACY_PAGE
INSTALLED_APPS.append("privacypage")  # noqa
endef

define WAGTAIL_SETTINGS_SITE_PAGE
INSTALLED_APPS.append("sitepage")  # noqa
endef

define WAGTAIL_SITE_PAGE_MODEL
from wagtail.models import Page


class SitePage(Page):
    template = "sitepage/site_page.html"

    class Meta:
        verbose_name = "Site Page"
endef

# ------------------------------------------------------------------------------
#  Wagtail Templates
# ------------------------------------------------------------------------------

define WAGTAIL_TEMPLATE_BASE
{% load static wagtailcore_tags wagtailuserbar webpack_loader %}
<!DOCTYPE html>
<html lang="en"
      class="h-100"
      data-bs-theme="{{ request.user.user_theme_preference|default:'light' }}">
    <head>
        <meta charset="utf-8" />
        <title>
            {% block title %}
                {% if page.seo_title %}
                    {{ page.seo_title }}
                {% else %}
                    {{ page.title }}
                {% endif %}
            {% endblock %}
            {% block title_suffix %}
                {% wagtail_site as current_site %}
                {% if current_site and current_site.site_name %}- {{ current_site.site_name }}{% endif %}
            {% endblock %}
        </title>
        {% if page.search_description %}<meta name="description" content="{{ page.search_description }}" />{% endif %}
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        {# Force all links in the live preview panel to be opened in a new tab #}
        {% if request.in_preview_panel %}<base target="_blank">{% endif %}
        {% stylesheet_pack 'app' %}
        {% block extra_css %}{# Override this in templates to add extra stylesheets #}{% endblock %}
        <style>
            .success {
                background-color: #d4edda;
                border-color: #c3e6cb;
                color: #155724;
            }

            .info {
                background-color: #d1ecf1;
                border-color: #bee5eb;
                color: #0c5460;
            }

            .warning {
                background-color: #fff3cd;
                border-color: #ffeeba;
                color: #856404;
            }

            .danger {
                background-color: #f8d7da;
                border-color: #f5c6cb;
                color: #721c24;
            }
        </style>
        {% include 'favicon.html' %}
        {% csrf_token %}
    </head>
    <body class="{% block body_class %}{% endblock %} d-flex flex-column h-100">
        <main class="flex-shrink-0">
            {% wagtailuserbar %}
            <div id="app"></div>
            {% include 'header.html' %}
            {% if messages %}
                <div class="messages container">
                    {% for message in messages %}
                        <div class="alert {{ message.tags }} alert-dismissible fade show"
                             role="alert">
                            {{ message }}
                            <button type="button"
                                    class="btn-close"
                                    data-bs-dismiss="alert"
                                    aria-label="Close"></button>
                        </div>
                    {% endfor %}
                </div>
            {% endif %}
            <div class="container">
                {% block content %}{% endblock %}
            </div>
        </main>
        {% include 'footer.html' %}
        {% include 'offcanvas.html' %}
        {% javascript_pack 'app' %}
        {% block extra_js %}{# Override this in templates to add extra javascript #}{% endblock %}
    </body>
</html>
endef

define WAGTAIL_TEMPLATE_CONTACT_PAGE
{% extends 'base.html' %}
{% load crispy_forms_tags static wagtailcore_tags %}
{% block content %}
        <h1>{{ page.title }}</h1>
        {{ page.intro|richtext }}
        <form action="{% pageurl page %}" method="POST">
            {% csrf_token %}
            {{ form.as_p }}
            <input type="submit">
        </form>
{% endblock %}
endef

define WAGTAIL_TEMPLATE_CONTACT_PAGE_LANDING
{% extends 'base.html' %}
{% block content %}<div class="container"><h1>Thank you!</h1></div>{% endblock %}
endef

define WAGTAIL_TEMPLATE_HOME_PAGE
{% extends "base.html" %}
{% load wagtailcore_tags %}
{% block content %}
    <main class="{% block main_class %}{% endblock %}">
        {% for block in page.marketing_blocks %}
            {% include_block block %}
        {% endfor %}
    </main>
{% endblock %}
endef

define WAGTAIL_TEMPLATE_PRIVACY_PAGE
{% extends 'base.html' %}
{% load wagtailmarkdown %}
{% block content %}<div class="container">{{ page.body|markdown }}</div>{% endblock %}
endef

define WAGTAIL_TEMPLATE_SEARCH
{% extends "base.html" %}
{% load static wagtailcore_tags %}
{% block body_class %}template-searchresults{% endblock %}
{% block title %}Search{% endblock %}
{% block content %}
    <h1>Search</h1>
    <form action="{% url 'search' %}" method="get">
        <input type="text"
               name="query"
               {% if search_query %}value="{{ search_query }}"{% endif %}>
        <input type="submit" value="Search" class="button">
    </form>
    {% if search_results %}
        <ul>
            {% for result in search_results %}
                <li>
                    <h4>
                        <a href="{% pageurl result %}">{{ result }}</a>
                    </h4>
                    {% if result.search_description %}{{ result.search_description }}{% endif %}
                </li>
            {% endfor %}
        </ul>
        {% if search_results.has_previous %}
            <a href="{% url 'search' %}?query={{ search_query|urlencode }}&amp;page={{ search_results.previous_page_number }}">Previous</a>
        {% endif %}
        {% if search_results.has_next %}
            <a href="{% url 'search' %}?query={{ search_query|urlencode }}&amp;page={{ search_results.next_page_number }}">Next</a>
        {% endif %}
    {% elif search_query %}
        No results found
    {% else %}
        No results found. Try a <a href="?query=test">test query</a>?
    {% endif %}
{% endblock %}
endef

define WAGTAIL_TEMPLATE_SITE_PAGE
{% extends 'base.html' %}
{% block content %}
    <h1>{{ page.title }}</h1>
{% endblock %}
endef

# ------------------------------------------------------------------------------
#  Wagtail URLs
# ------------------------------------------------------------------------------

define WAGTAIL_URLS
from django.conf import settings
from django.urls import include, path
from django.contrib import admin

from wagtail.admin import urls as wagtailadmin_urls
from wagtail.documents import urls as wagtaildocs_urls

from search import views as search_views

urlpatterns = [
    path("django/", admin.site.urls),
    path("wagtail/", include(wagtailadmin_urls)),
    path("documents/", include(wagtaildocs_urls)),
    path("search/", search_views.search, name="search"),
]

if settings.DEBUG:
    from django.conf.urls.static import static
    from django.contrib.staticfiles.urls import staticfiles_urlpatterns

    # Serve static and media files from development server
    urlpatterns += staticfiles_urlpatterns()
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
endef

define WAGTAIL_URLS_HOME
urlpatterns += [
    # For anything not caught by a more specific rule above, hand over to
    # Wagtail's page serving mechanism. This should be the last pattern in
    # the list:
    path("", include("wagtail.urls")),
    # Alternatively, if you want Wagtail pages to be served from a subpath
    # of your site, rather than the site root:
    #    path("pages/", include("wagtail.urls"),
]
endef

# ------------------------------------------------------------------------------
#  Webpack Configuration
#
#  For use with python-webpack-boilerplate
# ------------------------------------------------------------------------------

define WEBPACK_CONFIG_JS
const path = require('path');

module.exports = {
  mode: 'development',
  entry: './src/index.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
};
endef

define WEBPACK_INDEX_HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Hello, Webpack!</title>
</head>
<body>
  <script src="dist/bundle.js"></script>
</body>
</html>
endef

define WEBPACK_INDEX_JS
const message = "Hello, World!";
console.log(message);
endef

define WEBPACK_REVEAL_CONFIG_JS
const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
  mode: 'development',
  entry: './src/index.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
  module: {
    rules: [
      {
        test: /\.css$$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader'],
      },
    ],
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: 'bundle.css',
    }),
  ],
};
endef

define WEBPACK_REVEAL_INDEX_HTML
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Project Makefile</title>
        <link rel="stylesheet" href="dist/bundle.css">
    </head>
    <div class="reveal">
        <div class="slides">
            <section>
                Slide 1: Draw some circles
            </section>
            <section>
                Slide 2: Draw the rest of the owl
            </section>
        </div>
    </div>
    <script src="dist/bundle.js"></script>
</html>
endef

define WEBPACK_REVEAL_INDEX_JS
import 'reveal.js/dist/reveal.css';
import 'reveal.js/dist/theme/black.css';
import Reveal from 'reveal.js';
import RevealNotes from 'reveal.js/plugin/notes/notes.js';
Reveal.initialize({ slideNumber: true, plugins: [ RevealNotes ]});
endef

# ==============================================================================
# Export variables used by phony target rules
# ==============================================================================

export DJANGO_API_SERIALIZERS \
        DJANGO_API_VIEWS \
        DJANGO_ADMIN_CUSTOM_APPS \
        DJANGO_ADMIN_CUSTOM_ADMIN \
        DJANGO_DOCKER_COMPOSE \
        DJANGO_DOCKER_FILE \
        DJANGO_FRONTEND \
        DJANGO_FRONTEND_BABELRC \
        DJANGO_FRONTEND_CLOCK \
        DJANGO_FRONTEND_COMPONENTS \
        DJANGO_FRONTEND_CONFIG \
        DJANGO_FRONTEND_CONTEXT_INDEX \
        DJANGO_FRONTEND_CONTEXT_USER_PROVIDER \
        DJANGO_FRONTEND_ERROR \
        DJANGO_FRONTEND_ESLINTRC \
        DJANGO_FRONTEND_PORTAL \
        DJANGO_FRONTEND_STYLES \
        DJANGO_FRONTEND_THEME_BLUE \
        DJANGO_FRONTEND_THEME_TOGGLER \
        DJANGO_FRONTEND_TINYMCE_JS \
        DJANGO_FRONTEND_USER_MENU \
        DJANGO_HOME_PAGE_ADMIN \
        DJANGO_HOME_PAGE_MODELS \
        DJANGO_HOME_PAGE_URLS \
        DJANGO_HOME_PAGE_VIEWS \
        DJANGO_LOGGING_DEMO_ADMIN \
        DJANGO_LOGGING_DEMO_MODELS \
        DJANGO_LOGGING_DEMO_SETTINGS \
        DJANGO_LOGGING_DEMO_URLS \
        DJANGO_LOGGING_DEMO_VIEWS \
        DJANGO_MANAGE_PY \
        DJANGO_MODEL_FORM_DEMO_ADMIN \
        DJANGO_MODEL_FORM_DEMO_FORMS \
        DJANGO_MODEL_FORM_DEMO_MODELS \
        DJANGO_MODEL_FORM_DEMO_TEMPLATE_DETAIL \
        DJANGO_MODEL_FORM_DEMO_TEMPLATE_FORM \
        DJANGO_MODEL_FORM_DEMO_TEMPLATE_LIST \
        DJANGO_MODEL_FORM_DEMO_URLS \
        DJANGO_MODEL_FORM_DEMO_VIEWS \
	DJANGO_MONGODB_APPS \
        DJANGO_PAYMENTS_ADMIN \
        DJANGO_PAYMENTS_FORM \
        DJANGO_PAYMENTS_MIGRATION_0002 \
        DJANGO_PAYMENTS_MIGRATION_0003 \
        DJANGO_PAYMENTS_MODELS \
        DJANGO_PAYMENTS_TEMPLATE_CANCEL \
        DJANGO_PAYMENTS_TEMPLATE_CHECKOUT \
        DJANGO_PAYMENTS_TEMPLATE_PRODUCT_DETAIL \
        DJANGO_PAYMENTS_TEMPLATE_PRODUCT_LIST \
        DJANGO_PAYMENTS_TEMPLATE_SUCCESS \
        DJANGO_PAYMENTS_URLS \
        DJANGO_PAYMENTS_VIEW \
        DJANGO_SEARCH_FORMS \
        DJANGO_SEARCH_URLS \
        DJANGO_SEARCH_UTILS \
        DJANGO_SEARCH_VIEWS \
        DJANGO_SETTINGS_AUTHENTICATION_BACKENDS \
        DJANGO_SETTINGS_BASE \
        DJANGO_SETTINGS_CRISPY_FORMS \
        DJANGO_SETTINGS_DATABASE \
        DJANGO_SETTINGS_DEV \
        DJANGO_SETTINGS_HOME_PAGE \
        DJANGO_SETTINGS_INSTALLED_APPS \
        DJANGO_SETTINGS_MIDDLEWARE \
        DJANGO_SETTINGS_MODEL_FORM_DEMO \
	DJANGO_SETTINGS_MONGODB \
        DJANGO_SETTINGS_PAYMENTS \
        DJANGO_SETTINGS_PROD \
        DJANGO_SETTINGS_REST_FRAMEWORK \
        DJANGO_SETTINGS_SEARCH \
        DJANGO_SETTINGS_SITEUSER \
        DJANGO_SETTINGS_UNIT_TEST_DEMO \
        DJANGO_SITEUSER_ADMIN \
        DJANGO_SITEUSER_FORM \
        DJANGO_SITEUSER_MODEL \
        DJANGO_SITEUSER_URLS \
        DJANGO_SITEUSER_VIEW \
        DJANGO_TEMPLATE_ALLAUTH \
        DJANGO_TEMPLATE_BASE \
        DJANGO_TEMPLATE_FAVICON \
        DJANGO_TEMPLATE_FOOTER \
        DJANGO_TEMPLATE_HEADER \
        DJANGO_TEMPLATE_HOME_PAGE \
        DJANGO_TEMPLATE_OFFCANVAS \
        DJANGO_TEMPLATE_SEARCH \
        DJANGO_TEMPLATE_SITEUSER_EDIT \
        DJANGO_TEMPLATE_SITEUSER_VIEW \
        DJANGO_UNIT_TEST_DEMO_FORMS \
        DJANGO_UNIT_TEST_DEMO_MODELS \
        DJANGO_UNIT_TEST_DEMO_TESTS \
        DJANGO_URLS \
        DJANGO_URLS_ALLAUTH \
        DJANGO_URLS_API \
        DJANGO_URLS_DEBUG_TOOLBAR \
        DJANGO_URLS_HOME_PAGE \
        DJANGO_URLS_LOGGING_DEMO \
        DJANGO_URLS_MODEL_FORM_DEMO \
        DJANGO_URLS_PAYMENTS \
        DJANGO_URLS_SITEUSER \
        DJANGO_UTILS \
        EB_CUSTOM_ENV_EC2_USER \
        EB_CUSTOM_ENV_VAR_FILE \
        GIT_COMMIT_IGNORE \
        GIT_COMMIT_MESSAGE \
        JENKINS_FILE \
        LICENSE_TXT \
        PROJECT_CUSTOM \
        PIP_INSTALL_REQUIREMENTS_TEST \
        PROGRAMMING_INTERVIEW \
        PYTHON_PROJECT_TOML \
        SEPARATOR \
        WAGTAIL_BLOCK_CAROUSEL \
        WAGTAIL_BLOCK_MARKETING \
        WAGTAIL_CONTACT_PAGE_MODEL \
        WAGTAIL_CONTACT_PAGE_TESTS \
        WAGTAIL_HOME_PAGE_MODEL \
        WAGTAIL_HOME_PAGE_URLS \
        WAGTAIL_HOME_PAGE_VIEWS \
        WAGTAIL_PRIVACY_PAGE_MODEL \
        WAGTAIL_PRIVACY_PAGE_MODEL \
        WAGTAIL_SEARCH_URLS \
        WAGTAIL_SETTINGS \
        WAGTAIL_SETTINGS_CONTACT_PAGE \
        WAGTAIL_SETTINGS_PRIVACY_PAGE \
        WAGTAIL_SETTINGS_SITE_PAGE \
        WAGTAIL_SITE_PAGE_MODEL \
        WAGTAIL_URLS \
        WAGTAIL_URLS_HOME \
        WEBPACK_CONFIG_JS \
        WEBPACK_INDEX_HTML \
        WEBPACK_INDEX_JS \
        WEBPACK_REVEAL_CONFIG_JS \
        WEBPACK_REVEAL_INDEX_HTML \
        WEBPACK_REVEAL_INDEX_JS \
        WAGTAIL_TEMPLATE_BASE \
        WAGTAIL_TEMPLATE_CONTACT_PAGE \
        WAGTAIL_TEMPLATE_CONTACT_PAGE_LANDING \
        WAGTAIL_TEMPLATE_HOME_PAGE \
        WAGTAIL_TEMPLATE_PRIVACY_PAGE \
        WAGTAIL_TEMPLATE_SEARCH \
        WAGTAIL_TEMPLATE_SITE_PAGE

# ==============================================================================
# Multi-line phony target rules
# ==============================================================================

.PHONY: aws-check-env-profile-default
aws-check-env-profile-default:
ifndef AWS_PROFILE
	$(error AWS_PROFILE is undefined)
endif

.PHONY: aws-check-env-region-default
aws-check-env-region-default:
ifndef AWS_REGION
	$(error AWS_REGION is undefined)
endif

.PHONY: aws-secret-default
aws-secret-default: aws-check-env
	@SECRET_KEY=$$(openssl rand -base64 48); aws ssm put-parameter --name "SECRET_KEY" --value "$$SECRET_KEY" --type String

.PHONY: aws-sg-default
aws-sg-default: aws-check-env
	aws ec2 describe-security-groups $(AWS_OPTS)

.PHONY: aws-ssm-default
aws-ssm-default: aws-check-env
	aws ssm describe-parameters $(AWS_OPTS)
	@echo "Get parameter values with: aws ssm getparameter --name <Name>."

.PHONY: aws-subnet-default
aws-subnet-default: aws-check-env
	aws ec2 describe-subnets $(AWS_OPTS)

.PHONY: aws-vol-available-default
aws-vol-available-default: aws-check-env
	aws ec2 describe-volumes --filters Name=status,Values=available --query "Volumes[*].{ID:VolumeId,Size:Size}" --output table

.PHONY: aws-vol-default
aws-vol-default: aws-check-env
	aws ec2 describe-volumes --output table

.PHONY: aws-vpc-default
aws-vpc-default: aws-check-env
	aws ec2 describe-vpcs $(AWS_OPTS)

.PHONY: django-db-import-default
django-db-import-default:
	@psql $(PACKAGE_NAME) < $(EB_DJANGO_DATABASE_NAME).sql

.PHONY: django-db-init-default
django-db-init-postgres-default:
	-dropdb $(PACKAGE_NAME)
	-createdb $(PACKAGE_NAME)

.PHONY: django-db-init-mysql-default
django-db-init-mysql-default:
	-mysqladmin -u root drop $(PROJECT_NAME)
	-mysqladmin -u root create $(PROJECT_NAME)

.PHONY: django-db-init-mongodb-default
django-db-init-mongodb-default:
	-mongosh --eval "db.dropDatabase()"

.PHONY: db-init-test-default
db-init-test-default:
	-dropdb test_$(PACKAGE_NAME)
	-createdb test_$(PACKAGE_NAME)

.PHONY: django-admin-custom-default
django-admin-custom-default:
	@echo "$$DJANGO_ADMIN_CUSTOM_ADMIN" > $(DJANGO_ADMIN_CUSTOM_ADMIN_FILE)
	@echo "$$DJANGO_ADMIN_CUSTOM_APPS" > $(DJANGO_ADMIN_CUSTOM_APPS_FILE)
	-$(GIT_ADD) backend/*.py

.PHONY: django-allauth-default
django-allauth-default:
	$(ADD_DIR) backend/templates/allauth/layouts
	@echo "$$DJANGO_TEMPLATE_ALLAUTH" > backend/templates/allauth/layouts/base.html
	@echo "$$DJANGO_URLS_ALLAUTH" >> $(DJANGO_URLS_FILE)
	-$(GIT_ADD) backend/templates/allauth/layouts/base.html

.PHONY: django-api-serializers-default
django-api-serializers-default:
	@echo "$$DJANGO_API_SERIALIZERS" > backend/serializers.py
	-$(GIT_ADD) backend/serializers.py

.PHONY: django-api-views-default
django-api-views-default:
	@echo "$$DJANGO_API_VIEWS" > backend/api.py
	-$(GIT_ADD) backend/api.py

.PHONY: django-clean-default
django-clean-default:
	-@for dir in $(shell echo "$(DJANGO_CLEAN_DIRS)"); do \
		echo "Cleaning $$dir"; \
		$(DEL_DIR) $$dir >/dev/null 2>&1; \
	done
	-@for file in $(shell echo "$(DJANGO_CLEAN_FILES)"); do \
		echo "Cleaning $$file"; \
		$(DEL_FILE) $$file >/dev/null 2>&1; \
	done

.PHONY: django-db-shell-default
django-db-shell-default:
	python manage.py dbshell

.PHONY: django-dockerfile-default
django-dockerfile-default:
	@echo "$$DJANGO_DOCKER_COMPOSE" > docker-compose.yml
	-$(GIT_ADD) docker-compose.yml
	@echo "$$DJANGO_DOCKER_FILE" > Dockerfile
	-$(GIT_ADD) Dockerfile

.PHONY: django-frontend-default
django-frontend-default: python-webpack-init
	$(ADD_DIR) frontend/src/context
	$(ADD_DIR) frontend/src/images
	$(ADD_DIR) frontend/src/utils
	@echo "$$DJANGO_FRONTEND" > frontend/src/application/app.js
	@echo "$$DJANGO_FRONTEND_CONFIG" > frontend/src/application/config.js
	@echo "$$DJANGO_FRONTEND_BABELRC" > frontend/.babelrc
	@echo "$$DJANGO_FRONTEND_CLOCK" > frontend/src/components/Clock.js
	@echo "$$DJANGO_FRONTEND_ERROR" > frontend/src/components/ErrorBoundary.js
	@echo "$$DJANGO_FRONTEND_CONTEXT_INDEX" > frontend/src/context/index.js
	@echo "$$DJANGO_FRONTEND_CONTEXT_USER_PROVIDER" > frontend/src/context/UserContextProvider.js
	@echo "$$DJANGO_FRONTEND_USER_MENU" > frontend/src/components/UserMenu.js
	@echo "$$DJANGO_FRONTEND_COMPONENTS" > frontend/src/components/index.js
	@echo "$$DJANGO_FRONTEND_ESLINTRC" > frontend/.eslintrc
	@echo "$$DJANGO_FRONTEND_PORTAL" > frontend/src/dataComponents.js
	@echo "$$DJANGO_FRONTEND_STYLES" > frontend/src/styles/index.scss
	@echo "$$DJANGO_FRONTEND_THEME_BLUE" > frontend/src/styles/theme-blue.scss
	@echo "$$DJANGO_FRONTEND_THEME_TOGGLER" > frontend/src/utils/themeToggler.js
	-$(GIT_ADD) $(DJANGO_FRONTEND_FILES)

.PHONY: django-graph-default
django-graph-default:
	python manage.py graph_models -a -o $(PROJECT_NAME).png

.PHONY: django-home-page-default
django-home-page-default:
	python manage.py startapp home
	$(ADD_DIR) home/templates
	@echo "$$DJANGO_HOME_PAGE_ADMIN" > home/admin.py
	@echo "$$DJANGO_HOME_PAGE_MODELS" > home/models.py
	@echo "$$DJANGO_HOME_PAGE_VIEWS" > home/views.py
	@echo "$$DJANGO_HOME_PAGE_URLS" > home/urls.py
	@echo "$$DJANGO_URLS_HOME_PAGE" >> $(DJANGO_URLS_FILE)
	@echo "$$DJANGO_SETTINGS_HOME_PAGE" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_TEMPLATE_HOME_PAGE" > home/templates/home.html
	-$(GIT_ADD) home/*.py
	-$(GIT_ADD) home/migrations/*.py
	-$(GIT_ADD) home/templates/

# --------------------------------------------------------------------------------
#  Install Django
# --------------------------------------------------------------------------------
.PHONY: django-init-default
django-init-default: separator \
	django-db-init \
	django-clean \
	django-install \
	django-project \
	django-utils \
	pip-freeze \
	pip-init-test \
	django-settings-directory \
	django-admin-custom \
	django-dockerfile \
	django-template-base \
	django-template-header \
	django-template-favicon \
	django-template-footer \
	django-template-offcanvas \
	django-manage-py \
	django-urls \
	django-urls-debug-toolbar \
	django-allauth \
	django-search \
	django-settings-base \
	django-settings-dev \
	django-settings-prod \
	django-siteuser \
	django-home-page \
	django-api-views \
	django-api-serializers \
	django-urls-api \
	django-frontend \
	npm-install-react \
	npm-install-react-dev \
	django-migrate \
	.gitignore \
	django-su

# --------------------------------------------------------------------------------
#  Install Django with minimal dependencies
# --------------------------------------------------------------------------------
.PHONY: django-init-minimal-default
django-init-minimal-default: separator \
	django-db-init \
	django-clean \
	django-install-minimal \
	django-project \
	pip-freeze \
	pip-init-test \
	django-settings-directory \
	django-admin-custom \
	django-dockerfile \
	django-template-base \
	django-template-header \
	django-template-favicon \
	django-template-footer \
	django-template-offcanvas \
	django-manage-py \
	django-urls \
	django-urls-debug-toolbar \
	django-allauth \
	django-settings-base \
	django-settings-dev \
	django-settings-prod \
	django-siteuser \
	django-home-page \
	django-utils \
	django-frontend \
	npm-install-react \
	npm-install-react-dev \
	django-migrate \
	.gitignore \
	django-su

# --------------------------------------------------------------------------------
#  Install Wagtail
# --------------------------------------------------------------------------------

.PHONY: django-init-wagtail-default
django-init-wagtail-default: separator \
	django-db-init \
	django-clean \
	django-install \
	wagtail-install \
	wagtail-project \
	django-utils \
	pip-freeze \
	pip-init-test \
	django-admin-custom \
	django-dockerfile \
	wagtail-header-prefix-template \
	wagtail-base-template \
	django-template-favicon \
	django-template-footer \
	django-template-header \
	django-template-offcanvas \
	django-manage-py \
	wagtail-home \
	wagtail-urls \
	django-urls-debug-toolbar \
	django-allauth \
	wagtail-search \
	django-settings-base \
	django-settings-dev \
	django-settings-prod \
	wagtail-settings \
	django-siteuser \
	django-model-form-demo \
	django-unit-test-demo \
	django-logging-demo \
	django-payments-demo \
	wagtail-contact-page \
	wagtail-privacy-page \
	wagtail-site-page \
	django-api-views \
	django-api-serializers \
	django-urls-api \
	wagtail-urls-home \
	django-frontend \
	npm-install-react \
	npm-install-react-dev \
	django-migrate \
	.gitignore \
	django-su

.PHONY: django-install-default
django-install-default: pip-ensure
	$(PIP_INSTALL) \
	Django \
	Faker \
	PyMongo \
	boto3 \
	build \
	crispy-bootstrap5 \
	djangorestframework \
	django-allauth \
	django-after-response \
	django-ckeditor \
	django-colorful \
	django-cors-headers \
	django-countries \
	django-crispy-forms \
	django-debug-toolbar \
	django-extensions \
	django-hijack \
	django-honeypot \
	django-imagekit \
	django-import-export \
	django-ipware \
	-e git+https://github.com/mongodb-labs/django-mongodb#egg=django-mongodb \
	django-multiselectfield \
	django-ninja \
	django-phonenumber-field \
	django-recurrence \
	django-recaptcha \
	django-registration \
	django-richtextfield \
	django-sendgrid-v5 \
	django-social-share \
	django-sql-explorer \
	django-storages \
	django-tables2 \
	django-timezone-field \
	django-widget-tweaks \
	dj-database-url \
	dj-rest-auth \
	dj-stripe \
	dnspython \
	docutils \
	enmerkar \
	gunicorn \
	html2docx \
	icalendar \
	mailchimp-marketing \
	mailchimp-transactional \
	phonenumbers \
	psycopg2-binary \
	pydotplus \
	python-webpack-boilerplate \
	python-docx \
	reportlab \
	texttable \
	wheel

.PHONY: django-install-minimal-default
django-install-minimal-default: pip-ensure
	$(PIP_INSTALL) \
	Django \
	dj-database-url \
	django-debug-toolbar \
	python-webpack-boilerplate \
	django-allauth \
	django-crispy-forms \
	crispy-bootstrap5 \
	django-extensions \
	django-recaptcha \
	djangorestframework \
	django-sql-explorer \
	psycopg2-binary

.PHONY: django-lint-default
django-lint-default:
	-ruff format -v
	-djlint --reformat --format-css --format-js .
	-ruff check -v --fix

.PHONY: django-loaddata-default
django-loaddata-default:
	python manage.py loaddata

.PHONY: django-logging-demo-default
django-logging-demo-default:
	python manage.py startapp logging_demo
	@echo "$$DJANGO_LOGGING_DEMO_ADMIN" > logging_demo/admin.py
	@echo "$$DJANGO_LOGGING_DEMO_MODELS" > logging_demo/models.py
	@echo "$$DJANGO_LOGGING_DEMO_SETTINGS" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_LOGGING_DEMO_URLS" > logging_demo/urls.py
	@echo "$$DJANGO_LOGGING_DEMO_VIEWS" > logging_demo/views.py
	@echo "$$DJANGO_URLS_LOGGING_DEMO" >> $(DJANGO_URLS_FILE)
	-$(GIT_ADD) logging_demo/*.py
	-$(GIT_ADD) logging_demo/migrations/*.py

.PHONY: django-manage-py-default
django-manage-py-default:
	@echo "$$DJANGO_MANAGE_PY" > manage.py
	-$(GIT_ADD) manage.py

.PHONY: django-migrate-default
django-migrate-default:
	python manage.py migrate

.PHONY: django-migrate-mongodb-default
django-migrate-mongodb-default:
	$(ADD_DIR) backend/migrations
	python manage.py makemigrations account auth admin contenttypes
	-$(GIT_ADD) $(MONGODB_MIGRATIONS_DIR)/*.py

.PHONY: django-migrations-make-default
django-migrations-make-default:
	python manage.py makemigrations

.PHONY: django-migrations-show-default
django-migrations-show-default:
	python manage.py showmigrations

.PHONY: django-model-form-demo-default
django-model-form-demo-default:
	python manage.py startapp model_form_demo
	@echo "$$DJANGO_MODEL_FORM_DEMO_ADMIN" > model_form_demo/admin.py
	@echo "$$DJANGO_MODEL_FORM_DEMO_FORMS" > model_form_demo/forms.py
	@echo "$$DJANGO_MODEL_FORM_DEMO_MODELS" > model_form_demo/models.py
	@echo "$$DJANGO_MODEL_FORM_DEMO_URLS" > model_form_demo/urls.py
	@echo "$$DJANGO_MODEL_FORM_DEMO_VIEWS" > model_form_demo/views.py
	$(ADD_DIR) model_form_demo/templates
	@echo "$$DJANGO_MODEL_FORM_DEMO_TEMPLATE_DETAIL" > model_form_demo/templates/model_form_demo_detail.html
	@echo "$$DJANGO_MODEL_FORM_DEMO_TEMPLATE_FORM" > model_form_demo/templates/model_form_demo_form.html
	@echo "$$DJANGO_MODEL_FORM_DEMO_TEMPLATE_LIST" > model_form_demo/templates/model_form_demo_list.html
	-$(GIT_ADD) model_form_demo/templates
	@echo "$$DJANGO_SETTINGS_MODEL_FORM_DEMO" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_URLS_MODEL_FORM_DEMO" >> $(DJANGO_URLS_FILE)
	python manage.py makemigrations
	-$(GIT_ADD) model_form_demo/*.py
	-$(GIT_ADD) model_form_demo/migrations/*.py

.PHONY: django-mongodb-apps-default
django-mongodb-apps-default:
	@echo "$$DJANGO_MONGODB_APPS" > $(DJANGO_ADMIN_CUSTOM_APPS_FILE)
	-$(GIT_ADD) backend/*.py

.PHONY: django-open-default
django-open-default:
ifeq ($(UNAME), Linux)
	@echo "Opening on Linux."
	xdg-open http://0.0.0.0:8000
else ifeq ($(UNAME), Darwin)
	@echo "Opening on macOS (Darwin)."
	open http://0.0.0.0:8000
else
	@echo "Unable to open on: $(UNAME)"
endif

.PHONY: django-payments-demo-default
django-payments-demo-default:
	python manage.py startapp payments
	@echo "$$DJANGO_PAYMENTS_FORM" > payments/forms.py
	@echo "$$DJANGO_PAYMENTS_MODELS" > payments/models.py
	@echo "$$DJANGO_PAYMENTS_ADMIN" > payments/admin.py
	@echo "$$DJANGO_PAYMENTS_VIEW" > payments/views.py
	@echo "$$DJANGO_PAYMENTS_URLS" > payments/urls.py
	$(ADD_DIR) payments/templates/payments
	$(ADD_DIR) payments/management/commands
	@echo "$$DJANGO_PAYMENTS_TEMPLATE_CANCEL" > payments/templates/payments/cancel.html
	@echo "$$DJANGO_PAYMENTS_TEMPLATE_CHECKOUT" > payments/templates/payments/checkout.html
	@echo "$$DJANGO_PAYMENTS_TEMPLATE_SUCCESS" > payments/templates/payments/success.html
	@echo "$$DJANGO_PAYMENTS_TEMPLATE_PRODUCT_LIST" > payments/templates/payments/product_list.html
	@echo "$$DJANGO_PAYMENTS_TEMPLATE_PRODUCT_DETAIL" > payments/templates/payments/product_detail.html
	-$(GIT_ADD) payments/templates/payments
	@echo "$$DJANGO_SETTINGS_PAYMENTS" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_URLS_PAYMENTS" >> $(DJANGO_URLS_FILE)
	python manage.py makemigrations payments
	@echo "$$DJANGO_PAYMENTS_MIGRATION_0002" > payments/migrations/0002_set_stripe_api_keys.py
	@echo "$$DJANGO_PAYMENTS_MIGRATION_0003" > payments/migrations/0003_create_initial_products.py
	-$(GIT_ADD) payments/*.py
	-$(GIT_ADD) payments/migrations/*.py

.PHONY: django-project-default
django-project-default:
	django-admin startproject backend .
	-$(GIT_ADD) backend/*.py

.PHONY: django-search-default
django-search-default:
	python manage.py startapp search
	$(ADD_DIR) search/templates
	@echo "$$DJANGO_TEMPLATE_SEARCH" > search/templates/search.html
	-$(GIT_ADD) search/templates
	@echo "$$DJANGO_SEARCH_FORMS" > search/forms.py
	@echo "$$DJANGO_SEARCH_URLS" > search/urls.py
	@echo "$$DJANGO_SEARCH_UTILS" > search/utils.py
	@echo "$$DJANGO_SEARCH_VIEWS" > search/views.py
	@echo "$$DJANGO_SETTINGS_SEARCH" >> $(DJANGO_SETTINGS_BASE_FILE)
	-$(GIT_ADD) search/*.py
	-$(GIT_ADD) search/migrations/*.py

.PHONY: django-secret-key-default
django-secret-key-default:
	@python -c "from secrets import token_urlsafe; print(token_urlsafe(50))"

.PHONY: django-serve-default
django-serve-default:
	npm run watch &
	python manage.py runserver 0.0.0.0:8000

.PHONY: django-settings-base-default
django-settings-base-default:
	@echo "$$DJANGO_SETTINGS_BASE" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_SETTINGS_AUTHENTICATION_BACKENDS" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_SETTINGS_REST_FRAMEWORK" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_SETTINGS_DATABASE" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_SETTINGS_INSTALLED_APPS" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_SETTINGS_MIDDLEWARE" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_SETTINGS_CRISPY_FORMS" >> $(DJANGO_SETTINGS_BASE_FILE)

.PHONY: django-settings-dev-default
django-settings-dev-default:
	@echo "# $(PROJECT_NAME)" > $(DJANGO_SETTINGS_DEV_FILE)
	@echo "$$DJANGO_SETTINGS_DEV" >> backend/settings/dev.py
	-$(GIT_ADD) $(DJANGO_SETTINGS_DEV_FILE)

.PHONY: django-settings-directory-default
django-settings-directory-default:
	@$(ADD_DIR) $(DJANGO_SETTINGS_DIR)
	@$(COPY_FILE) backend/settings.py backend/settings/base.py
	@$(DEL_FILE) backend/settings.py
	-$(GIT_ADD) backend/settings/*.py

.PHONY: django-settings-mongodb-default
django-settings-mongodb-default:
	@echo "$$DJANGO_SETTINGS_MONGODB" >> $(DJANGO_SETTINGS_BASE_FILE)

.PHONY: django-settings-prod-default
django-settings-prod-default:
	@echo "$$DJANGO_SETTINGS_PROD" > $(DJANGO_SETTINGS_PROD_FILE)
	-$(GIT_ADD) $(DJANGO_SETTINGS_PROD_FILE)

.PHONY: django-shell-default
django-shell-default:
	python manage.py shell

.PHONY: django-siteuser-default
django-siteuser-default:
	python manage.py startapp siteuser
	$(ADD_DIR) siteuser/templates/
	@echo "$$DJANGO_SITEUSER_FORM" > siteuser/forms.py
	@echo "$$DJANGO_SITEUSER_MODEL" > siteuser/models.py
	@echo "$$DJANGO_SITEUSER_ADMIN" > siteuser/admin.py
	@echo "$$DJANGO_SITEUSER_VIEW" > siteuser/views.py
	@echo "$$DJANGO_SITEUSER_URLS" > siteuser/urls.py
	@echo "$$DJANGO_URLS_SITEUSER" >> $(DJANGO_URLS_FILE)
	@echo "$$DJANGO_SETTINGS_SITEUSER" >> $(DJANGO_SETTINGS_BASE_FILE)
	@echo "$$DJANGO_TEMPLATE_SITEUSER_EDIT" > siteuser/templates/user_edit.html
	@echo "$$DJANGO_TEMPLATE_SITEUSER_VIEW" > siteuser/templates/user.html
	-$(GIT_ADD) siteuser/templates
	-$(GIT_ADD) siteuser/*.py
	python manage.py makemigrations siteuser
	-$(GIT_ADD) siteuser/migrations/*.py

.PHONY: django-sqlmigrate-default
django-sqlmigrate-default:
	python manage.py sqlmigrate $(app_label) $(migration_name)

.PHONY: django-static-default
django-static-default:
	python manage.py collectstatic --noinput

.PHONY: django-su-default
django-su-default:
	DJANGO_SUPERUSER_PASSWORD=admin python manage.py createsuperuser --noinput --username=admin --email=$(PROJECT_EMAIL)

.PHONY: django-template-base-default
django-template-base-default:
	@$(ADD_DIR) backend/templates
	@echo "$$DJANGO_TEMPLATE_BASE" > backend/templates/base.html
	-$(GIT_ADD) backend/templates/base.html

.PHONY: django-template-favicon-default
django-template-favicon-default:
	@echo "$$DJANGO_TEMPLATE_FAVICON" > backend/templates/favicon.html
	-$(GIT_ADD) backend/templates/favicon.html

.PHONY: django-template-footer-default
django-template-footer-default:
	@echo "$$DJANGO_TEMPLATE_FOOTER" > backend/templates/footer.html
	-$(GIT_ADD) backend/templates/footer.html

.PHONY: django-template-header-default
django-template-header-default:
	@$(ADD_DIR) backend/templates
	@echo "$$DJANGO_TEMPLATE_HEADER" > backend/templates/header.html
	-$(GIT_ADD) backend/templates/header.html

.PHONY: django-template-offcanvas-default
django-template-offcanvas-default:
	-$(ADD_DIR) backend/templates
	@echo "$$DJANGO_TEMPLATE_OFFCANVAS" > backend/templates/offcanvas.html
	-$(GIT_ADD) backend/templates/offcanvas.html

.PHONY: django-test-default
django-test-default:
	python manage.py test

.PHONY: django-unit-test-demo-default
django-unit-test-demo-default:
	python manage.py startapp unit_test_demo
	@echo "$$DJANGO_UNIT_TEST_DEMO_FORMS" > unit_test_demo/forms.py
	@echo "$$DJANGO_UNIT_TEST_DEMO_MODELS" > unit_test_demo/models.py
	@echo "$$DJANGO_UNIT_TEST_DEMO_TESTS" > unit_test_demo/tests.py
	@echo "$$DJANGO_SETTINGS_UNIT_TEST_DEMO" >> $(DJANGO_SETTINGS_BASE_FILE)
	python manage.py makemigrations
	-$(GIT_ADD) unit_test_demo/*.py
	-$(GIT_ADD) unit_test_demo/migrations/*.py

.PHONY: django-urls-api-default
django-urls-api-default:
	@echo "$$DJANGO_URLS_API" >> $(DJANGO_URLS_FILE)
	-$(GIT_ADD) $(DJANGO_URLS_FILE)

.PHONY: django-urls-debug-toolbar-default
django-urls-debug-toolbar-default:
	@echo "$$DJANGO_URLS_DEBUG_TOOLBAR" >> $(DJANGO_URLS_FILE)

.PHONY: django-urls-default
django-urls-default:
	@echo "$$DJANGO_URLS" > $(DJANGO_URLS_FILE)
	-$(GIT_ADD) $(DJANGO_URLS_FILE)

.PHONY: django-urls-show-default
django-urls-show-default:
	python manage.py show_urls

.PHONY: django-user-default
django-user-default:
	python manage.py shell -c "from django.contrib.auth.models import User; \
        User.objects.create_user('user', '', 'user')"

.PHONY: django-utils-default
django-utils-default:
	@echo "$$DJANGO_UTILS" > backend/utils.py
	-$(GIT_ADD) backend/utils.py

.PHONY: docker-build-default
docker-build-default:
	podman build -t $(PROJECT_NAME) .

.PHONY: docker-compose-default
docker-compose-default:
	podman compose up

.PHONY: docker-list-default
docker-list-default:
	podman container list --all
	podman images --all

.PHONY: docker-run-default
docker-run-default:
	podman run $(PROJECT_NAME)

.PHONY: docker-serve-default
docker-serve-default:
	podman run -p 8000:8000 $(PROJECT_NAME)

.PHONY: docker-shell-default
docker-shell-default:
	podman run -it $(PROJECT_NAME) /bin/bash

.PHONY: eb-check-env-default
eb-check-env-default:  # https://stackoverflow.com/a/4731504/185820
ifndef EB_SSH_KEY
	$(error EB_SSH_KEY is undefined)
endif
ifndef VPC_ID
	$(error VPC_ID is undefined)
endif
ifndef VPC_SG
	$(error VPC_SG is undefined)
endif
ifndef VPC_SUBNET_EC2
	$(error VPC_SUBNET_EC2 is undefined)
endif
ifndef VPC_SUBNET_ELB
	$(error VPC_SUBNET_ELB is undefined)
endif

.PHONY: eb-create-default
eb-create-default: aws-check-env eb-check-env
	eb create $(EB_ENV_NAME) \
         -im $(EC2_INSTANCE_MIN) \
         -ix $(EC2_INSTANCE_MAX) \
         -ip $(EC2_INSTANCE_PROFILE) \
         -i $(EC2_INSTANCE_TYPE) \
         -k $(EB_SSH_KEY) \
         -p $(EB_PLATFORM) \
         --elb-type $(EC2_LB_TYPE) \
         --vpc \
         --vpc.id $(VPC_ID) \
         --vpc.elbpublic \
         --vpc.publicip \
         --vpc.ec2subnets $(VPC_SUBNET_EC2) \
         --vpc.elbsubnets $(VPC_SUBNET_ELB) \
         --vpc.securitygroups $(VPC_SG)

.PHONY: eb-custom-env-default
eb-custom-env-default:
	$(ADD_DIR) .ebextensions
	@echo "$$EB_CUSTOM_ENV_EC2_USER" > .ebextensions/bash.config
	-$(GIT_ADD) .ebextensions/bash.config
	$(ADD_DIR) .platform/hooks/postdeploy
	@echo "$$EB_CUSTOM_ENV_VAR_FILE" > .platform/hooks/postdeploy/setenv.sh
	-$(GIT_ADD) .platform/hooks/postdeploy/setenv.sh

.PHONY: eb-deploy-default
eb-deploy-default:
	eb deploy

.PHONY: eb-export-default
eb-export-default:
	@if [ ! -d $(EB_DIR_NAME) ]; then \
        echo "Directory $(EB_DIR_NAME) does not exist"; \
        else \
        echo "Found $(EB_DIR_NAME) directory"; \
        eb ssh --quiet -c "export PGPASSWORD=$(EB_DJANGO_DATABASE_PASS); pg_dump -U $(EB_DJANGO_DATABASE_USER) -h $(EB_DJANGO_DATABASE_HOST) $(EB_DJANGO_DATABASE_NAME)" > $(EB_DJANGO_DATABASE_NAME).sql; \
        echo "Wrote $(EB_DJANGO_DATABASE_NAME).sql"; \
        fi

.PHONY: eb-init-default
eb-init-default: aws-check-env-profile
	eb init --profile=$(AWS_PROFILE)

.PHONY: eb-list-databases-default
eb-list-databases-default:
	@eb ssh --quiet -c "export PGPASSWORD=$(EB_DJANGO_DATABASE_PASS); psql -l -U $(EB_DJANGO_DATABASE_USER) -h $(EB_DJANGO_DATABASE_HOST) $(EB_DJANGO_DATABASE_NAME)"

.PHONY: eb-list-platforms-default
eb-list-platforms-default:
	aws elasticbeanstalk list-platform-versions

.PHONY: eb-logs-default
eb-logs-default:
	eb logs

.PHONY: eb-print-env-default
eb-print-env-default:
	eb printenv

.PHONY: eb-rebuild-default
eb-rebuild-default:
	aws elasticbeanstalk rebuild-environment --environment-name $(ENV_NAME)

.PHONY: eb-restart-default
eb-restart-default:
	eb ssh -c "systemctl restart web"

.PHONY: eb-upgrade-default
eb-upgrade-default:
	eb upgrade

.PHONY: favicon-default
favicon-default:
	@dd if=/dev/urandom bs=64 count=1 status=none | base64 |\
		convert -size 16x16 -depth 8 -background none -fill white label:@- favicon.png
	@convert favicon.png favicon.ico
	@$(DEL_FILE) favicon.png
	-$(GIT_ADD) favicon.ico

.PHONY: gh-run-delete-default
gh-run-delete-default:
	@for run_id in $(shell gh run list --limit 100 --json databaseId --jq '.[].databaseId'); do \
          echo $$run_id; \
          gh run delete $$run_id; \
        done

.PHONY: git-checkout-branches-default
git-checkout-branches-default:
	@for i in $(GIT_BRANCHES); do \
          $(GIT_CHECKOUT) -t $$i; \
        done

.PHONY: git-commit-default
git-commit-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Update $(PROJECT_NAME) files")

.PHONY: git-commit-edit-default
git-commit-edit-default:
	-$(GIT_COMMIT) -a

.PHONY: git-commit-empty-default
git-commit-empty-default:
	-@$(GIT_COMMIT) --allow-empty -m $(call GIT_COMMIT_MESSAGE,"Empty commit")

.PHONY: git-commit-last-default
git-commit-last-default:
	@git log -1 --pretty=%B > $(TMPDIR)/commit.txt
	-@$(GIT_COMMIT) -a -F $(TMPDIR)/commit.txt

.PHONY: git-commit-message-actions-default
git-commit-message-actions-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Update actions")

.PHONY: git-commit-message-clean-default
git-commit-message-clean-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Clean up")

.PHONY: git-commit-message-comment-default
git-commit-message-comment-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Add comment")

.PHONY: git-commit-message-default
git-commit-message-default:
	-@$(GIT_COMMIT) -a -m "$(m)"

.PHONY: git-commit-message-freeze-default
git-commit-message-freeze-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Freeze")

.PHONY: git-commit-message-ignore-default
git-commit-message-ignore-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Add .gitignore")

.PHONY: git-commit-message-init-default
git-commit-message-init-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Init")

.PHONY: git-commit-message-lint-default
git-commit-message-lint-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Lint")

.PHONY: git-commit-message-project-custom-default
git-commit-message-project-custom-default:
	-@$(GIT_COMMIT) project.mk -m $(call GIT_COMMIT_MESSAGE,"Add/update $(PROJECT_CUSTOM_FILE)")

.PHONY: git-commit-message-readme-default
git-commit-message-readme-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Update readme")

.PHONY: git-commit-message-rename-default
git-commit-message-rename-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Rename")

.PHONY: git-commit-message-reword-default
git-commit-message-reword-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Reword")

.PHONY: git-commit-message-sort-default
git-commit-message-sort-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Sort")

.PHONY: git-commit-message-typo-default
git-commit-message-typo-default:
	-@$(GIT_COMMIT) -a -m $(call GIT_COMMIT_MESSAGE,"Fix typo")

.PHONY: git-prune-default
git-prune-default:
	git remote update origin --prune

.PHONY: git-push-default
git-push-default:
	-@$(GIT_PUSH)

.PHONY: git-push-force-default
git-push-force-default:
	-@$(GIT_PUSH_FORCE)

.PHONY: git-set-default-default
git-set-default-default:
	gh repo set-default

.PHONY: git-set-upstream-default
git-set-upstream-default:
	$(GIT_PUSH) --set-upstream origin main

.PHONY: git-short-default
git-short-default:
	@echo $(GIT_REV)

.PHONY: git-status-default
git-status-default:
	-@$(GIT_STATUS)

.PHONY: help-default
help-default:
	@echo "Project Makefile"
	@echo ""
	@echo "\"I like to type make <target> to perform tasks 🤷.\" —Alex"
	@echo ""
	@echo "Usage: make <target1> [target2 ...]"
	@echo "Examples:"
	@echo "   make help                   Print this message"
	@echo "   make list-targets           List all targets"
	@echo "   make django-init            Install Django"
	@echo "   make django-init-minimal    Install Django with minimal dependencies"
	@echo "   make django-init-wagtail    Install Wagtail"

.PHONY: jenkins-init-default
jenkins-init-default:
	@echo "$$JENKINS_FILE" > Jenkinsfile

.PHONY: license-default
license-default:
	@echo "$$LICENSE_TXT" > LICENSE.txt
	-$(GIT_ADD) LICENSE.txt

# --------------------------------------------------------------------------------
# Makefile-specific targets
# --------------------------------------------------------------------------------

.PHONY: make-default
make-default:
	-$(GIT_ADD) Makefile
	-@$(GIT_COMMIT) Makefile -m $(call GIT_COMMIT_MESSAGE,"Add/update $(PROJECT_NAME) Makefile")
	-$(GIT_PUSH)

.PHONY: make-list-targets-default
make-list-targets-default:
	@for makefile in $(MAKEFILE_LIST); do \
        echo "-- $$makefile --"; \
        $(MAKE) -pRrq -f $$makefile : 2>/dev/null | \
        awk -v RS= -F: '/^# File/,/^# Finished Make data base/ { \
            if ($$1 !~ "^[#.]") { sub(/-default$$/, "", $$1); print $$1 } }' | \
        egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | \
        tr ' ' '\n' | \
        sort | \
        awk '{print $$0}' ; \
        echo; \
    	done | $(PAGER)

.PHONY: make-list-defines-default
make-list-defines-default:
	@grep '^define [A-Za-z_][A-Za-z0-9_]*' Makefile

.PHONY: make-list-targets-deps-default
make-list-targets-deps-default:
	@perl -ne 'print if /^\s*\.PHONY:/ .. /^[a-zA-Z0-9_-]+:/;' Makefile | grep -v .PHONY

# --------------------------------------------------------------------------------
#  npm targets
# --------------------------------------------------------------------------------

.PHONY: npm-audit-fix-default
npm-audit-fix-default:
	npm audit fix --force

.PHONY: npm-build-default
npm-build-default:
	npm run build

.PHONY: npm-init-default
npm-init-default:
	npm init -y
	-$(GIT_ADD) package.json
	-$(GIT_ADD) package-lock.json

.PHONY: npm-install-default
npm-install-default:
	npm install
	-$(GIT_ADD) package-lock.json

# Skip these for now due to GitHub Actions authentication issues
# @fortawesome/fontawesome-svg-core \
# @fortawesome/react-fontawesome \
# @fortawesome/fontawesome-free \
# @fortawesome/free-brands-svg-icons \
# @fortawesome/free-solid-svg-icons \
.PHONY: npm-install-react-default
npm-install-react-default:
	$(DEL_FILE) package-lock.json
	npm install \
        bootstrap \
        camelize \
        date-fns \
        history \
        mapbox-gl \
        query-string \
        react-animate-height \
        react-chartjs-2 \
        react-copy-to-clipboard \
        react-date-range \
        react-dom \
        react-dropzone \
        react-hook-form \
        react-image-crop \
        react-map-gl \
        react-modal \
        react-resize-detector \
        react-select \
        react-swipeable \
        snakeize \
        striptags \
        url-join \
        viewport-mercator-project

.PHONY: npm-install-react-dev-default
npm-install-react-dev-default:
	npm install \
        eslint-plugin-react \
        eslint-config-standard \
        eslint-config-standard-jsx \
        @babel/core \
        @babel/preset-env \
        @babel/preset-react \
        --save-dev

.PHONY: npm-serve-default
npm-serve-default:
	npm run start

.PHONY: npm-test-default
npm-test-default:
	npm run test

# --------------------------------------------------------------------------------
#  pip targets
# --------------------------------------------------------------------------------

.PHONY: pip-deps-default
pip-deps-default: pip-ensure
	$(PIP_DEPS)

.PHONY: pip-ensure-default
pip-ensure-default:
	$(PIP_ENSURE)

.PHONY: pip-freeze-default
pip-freeze-default: pip-ensure
	$(PIP_FREEZE) | sort > requirements.txt
	-$(GIT_ADD) requirements.txt

.PHONY: pip-init-default
pip-init-default:
	touch requirements.txt
	-$(GIT_ADD) requirements.txt

.PHONY: pip-init-test-default
pip-init-test-default:
	@echo "$$PIP_INSTALL_REQUIREMENTS_TEST" > requirements-test.txt
	-$(GIT_ADD) requirements-test.txt

.PHONY: pip-install-default
pip-install-default: pip-ensure
	$(PIP_INSTALL) -r requirements.txt

.PHONY: pip-install-dev-default
pip-install-dev-default: pip-ensure
	$(PIP_INSTALL) -r requirements-dev.txt

.PHONY: pip-install-test-default
pip-install-test-default: pip-ensure
	$(PIP_INSTALL) -r requirements-test.txt

.PHONY: pip-install-upgrade-default
pip-install-upgrade-default: pip-ensure
	awk -F\= '{print $$1}' requirements.txt > $(TMPDIR)/requirements.txt
	$(COPY_FILE) $(TMPDIR)/requirements.txt .
	$(PIP_INSTALL) -U -r requirements.txt
	$(PIP_FREEZE) | sort > $(TMPDIR)/requirements.txt
	$(COPY_FILE) $(TMPDIR)/requirements.txt .

.PHONY: pip-uninstall-default
pip-uninstall-default: pip-ensure
	$(PIP_FREEZE) | xargs $(PIP_UNINSTALL)

.PHONY: pip-upgrade-default
pip-upgrade-default: pip-ensure
	$(PIP_INSTALL) -U pip

# --------------------------------------------------------------------------------
#  Plone targets
# --------------------------------------------------------------------------------

.PHONY: plone-clean-default
plone-clean-default:
	$(DEL_DIR) $(PROJECT_NAME)
	$(DEL_DIR) $(PACKAGE_NAME)

.PHONY: plone-init-default
plone-init-default: plone-install plone-instance plone-serve

.PHONY: plone-install-default
plone-install-default: pip-ensure
	$(PIP_INSTALL) plone -c $(PLONE_VERSION_FILE)

.PHONY: plone-instance-default
plone-instance-default:
	mkwsgiinstance -d backend -u admin:admin
	@sed -i -e 's/host = 127.0.0.1/host = 0.0.0.0/; s/port = 8080/port = 8000/' backend/etc/zope.ini
	@python -c "with open('backend/etc/zope.conf', 'r+') as f: lines = f.readlines(); f.seek(0);\
		f.writelines([line + '     blob-dir \$$INSTANCE/blobstorage\n' if 'path \$$INSTANCE/var/Data.fs'\
		in line else line for line in lines])"
	-$(GIT_ADD) backend/etc/site.zcml
	-$(GIT_ADD) backend/etc/zope.conf
	-$(GIT_ADD) backend/etc/zope.ini

.PHONY: plone-serve-default
plone-serve-default:
	runwsgi backend/etc/zope.ini

.PHONY: programming-interview-default
programming-interview-default:
	@echo "$$PROGRAMMING_INTERVIEW" > interview.py
	@echo "Created interview.py!"
	-$(GIT_ADD) interview.py > /dev/null 2>&1

# --------------------------------------------------------------------------------
#  python targets
# --------------------------------------------------------------------------------

.PHONY: python-project-default
python-project-default:
	@echo "$(PYTHON_PROJECT_TOML)" > pyproject.toml
	-$(GIT_ADD) pyproject.toml

.PHONY: python-sdist-default
python-sdist-default: pip-ensure
	python setup.py sdist --format=zip

.PHONY: python-serve-default
python-serve-default:
	@echo "\n\tServing HTTP on http://0.0.0.0:8000\n"
	$(PYTHON_HTTP_SERVER)


.PHONY: python-venv-check-default
python-venv-check-default:
ifndef VIRTUAL_ENV
	$(error VIRTUAL_ENV is not set)
endif

.PHONY: python-webpack-init-default
python-webpack-init-default:
	python manage.py webpack_init --no-input

.PHONY: rand-default
rand-default:
	@openssl rand -base64 12 | sed 's/\///g'

.PHONY: readme-init-default
readme-init-default:
	@echo "# $(PROJECT_NAME)" > README.md
	-$(GIT_ADD) README.md

.PHONY: readme-edit-default
readme-edit-default:
	$(EDITOR) README.md

.PHONY: reveal-init-default
reveal-init-default: webpack-init-reveal
	npm install \
	css-loader \
	mini-css-extract-plugin \
	reveal.js \
	style-loader
	jq '.scripts += {"build": "webpack"}' package.json > \
	$(TMPDIR)/tmp.json && mv $(TMPDIR)/tmp.json package.json
	jq '.scripts += {"start": "webpack serve --mode development --port 8000 --static"}' package.json > \
	$(TMPDIR)/tmp.json && mv $(TMPDIR)/tmp.json package.json
	jq '.scripts += {"watch": "webpack watch --mode development"}' package.json > \
	$(TMPDIR)/tmp.json && mv $(TMPDIR)/tmp.json package.json

.PHONY: reveal-serve-default
reveal-serve-default:
	npm run watch &
	$(PYTHON_HTTP_SERVER)

.PHONY: review-default
review-default:
ifeq ($(UNAME), Darwin)
	$(EDITOR_REVIEW) `find backend/ -name \*.py` `find backend/ -name \*.html` `find frontend/ -name \*.js` `find frontend/ -name \*.js`
else
	@echo "Unsupported"
endif

.PHONY: separator-default
separator-default:
	@echo "$$SEPARATOR"

# --------------------------------------------------------------------------------
#  Sphinx targets
# --------------------------------------------------------------------------------

.PHONY: sphinx-build-default
sphinx-build-default:
	@sphinx-build -b html -d _build/doctrees . _build/html
	@sphinx-build -b rinoh . _build/rinoh

.PHONY: sphinx-init-default
sphinx-init-default: sphinx-install
	sphinx-quickstart -q -p $(PROJECT_NAME) -a $(USER) -v 0.0.1 $(RANDIR)
	$(COPY_DIR) $(RANDIR)/* .
	$(DEL_DIR) $(RANDIR)
	-$(GIT_ADD) index.rst
	-$(GIT_ADD) conf.py
	$(DEL_FILE) make.bat
	-@$(GIT_CHECKOUT) Makefile

.PHONY: sphinx-install-default
sphinx-install-default:
	$(PIP_INSTALL) Sphinx
	$(PIP_FREEZE) | sort > requirements.txt
	-$(GIT_ADD) requirements.txt

.PHONY: sphinx-serve-default
sphinx-serve-default:
	cd _build/html;python3 -m http.server

.PHONY: sphinx-theme-default
sphinx-theme-default:
	@export SPHINX_THEME=$(PACKAGE_NAME)_theme; \
	    $(ADD_DIR) $$SPHINX_THEME; \
	    $(ADD_FILE) $$SPHINX_THEME/__init__.py; \
	    $(GIT_ADD) $$SPHINX_THEME/__init__.py; \
	    $(ADD_FILE) $$SPHINX_THEME/theme.conf; \
	    $(GIT_ADD) $$SPHINX_THEME/theme.conf; \
	    $(ADD_FILE) $$SPHINX_THEME/layout.html; \
	    $(GIT_ADD) $$SPHINX_THEME/layout.html; \
	    $(ADD_DIR) $$SPHINX_THEME/static/css; \
	    $(ADD_FILE) $$SPHINX_THEME/static/css/style.css; \
	    $(ADD_DIR) $$SPHINX_THEME/static/js; \
	    $(ADD_FILE) $$SPHINX_THEME/static/js/script.js; \
	    $(GIT_ADD) $$SPHINX_THEME/static

# --------------------------------------------------------------------------------
#  Wagtail targets
# --------------------------------------------------------------------------------

.PHONY: wagtail-base-template-default
wagtail-base-template-default:
	@echo "$$WAGTAIL_TEMPLATE_BASE" > backend/templates/base.html

.PHONY: wagtail-contact-page-default
wagtail-contact-page-default:
	python manage.py startapp contactpage
	@echo "$$WAGTAIL_CONTACT_PAGE_MODEL" > contactpage/models.py
	@echo "$$WAGTAIL_CONTACT_PAGE_TESTS" > contactpage/tests.py
	$(ADD_DIR) contactpage/templates/contactpage/
	@echo "$$WAGTAIL_TEMPLATE_CONTACT_PAGE" > contactpage/templates/contactpage/contact_page.html
	@echo "$$WAGTAIL_TEMPLATE_CONTACT_PAGE_LANDING" > contactpage/templates/contactpage/contact_page_landing.html
	-$(GIT_ADD) contactpage/templates/
	@echo "$$WAGTAIL_SETTINGS_CONTACT_PAGE" >> $(DJANGO_SETTINGS_BASE_FILE)
	python manage.py makemigrations contactpage
	-$(GIT_ADD) contactpage/*.py
	-$(GIT_ADD) contactpage/migrations/*.py

.PHONY: wagtail-header-prefix-template-default
wagtail-header-prefix-template-default:
	@echo "$$WAGTAIL_HEADER_PREFIX" > backend/templates/header.html

.PHONY: wagtail-home-default
wagtail-home-default:
	@echo "$$WAGTAIL_HOME_PAGE_MODEL" > home/models.py
	@echo "$$WAGTAIL_TEMPLATE_HOME_PAGE" > home/templates/home/home_page.html
	$(ADD_DIR) home/templates/blocks
	@echo "$$WAGTAIL_BLOCK_MARKETING" > home/templates/blocks/marketing_block.html
	@echo "$$WAGTAIL_BLOCK_CAROUSEL" > home/templates/blocks/carousel_block.html
	-$(GIT_ADD) home/templates
	python manage.py makemigrations home
	-$(GIT_ADD) home/*.py
	-$(GIT_ADD) home/migrations/*.py

.PHONY: wagtail-install-default
wagtail-install-default: pip-ensure
	$(PIP_INSTALL) \
        wagtail \
        wagtailmenus \
        wagtail-color-panel \
        wagtail-django-recaptcha \
        wagtail-markdown \
        wagtail-modeladmin \
        wagtail-seo \
        weasyprint \
        whitenoise \
        xhtml2pdf

.PHONY: wagtail-private-default
wagtail-privacy-page-default:
	python manage.py startapp privacypage
	@echo "$$WAGTAIL_PRIVACY_PAGE_MODEL" > privacypage/models.py
	$(ADD_DIR) privacypage/templates
	@echo "$$WAGTAIL_TEMPLATE_PRIVACY_PAGE" > privacypage/templates/privacy_page.html
	-$(GIT_ADD) privacypage/templates
	@echo "$$WAGTAIL_SETTINGS_PRIVACY_PAGE" >> $(DJANGO_SETTINGS_BASE_FILE)
	python manage.py makemigrations privacypage
	-$(GIT_ADD) privacypage/*.py
	-$(GIT_ADD) privacypage/migrations/*.py

.PHONY: wagtail-project-default
wagtail-project-default:
	wagtail start backend .
	$(DEL_FILE) home/templates/home/welcome_page.html
	-$(GIT_ADD) backend/*.py
	-$(GIT_ADD) backend/settings/*.py
	-$(GIT_ADD) backend/templates/
	-$(GIT_ADD) .dockerignore
	-$(GIT_ADD) Dockerfile
	-$(GIT_ADD) manage.py
	-$(GIT_ADD) requirements.txt

.PHONY: wagtail-search-default
wagtail-search-default:
	@echo "$$WAGTAIL_TEMPLATE_SEARCH" > search/templates/search/search.html
	-$(GIT_ADD) search/templates
	@echo "$$WAGTAIL_SEARCH_URLS" > search/urls.py
	-$(GIT_ADD) search/*.py

.PHONY: wagtail-settings-default
wagtail-settings-default:
	@echo "$$WAGTAIL_SETTINGS" >> $(DJANGO_SETTINGS_BASE_FILE)

.PHONY: wagtail-site-page-default
wagtail-site-page-default:
	python manage.py startapp sitepage
	@echo "$$WAGTAIL_SITE_PAGE_MODEL" > sitepage/models.py
	$(ADD_DIR) sitepage/templates/sitepage/
	@echo "$$WAGTAIL_TEMPLATE_SITE_PAGE" > sitepage/templates/sitepage/site_page.html
	-$(GIT_ADD) sitepage/templates
	@echo "$$WAGTAIL_SETTINGS_SITE_PAGE" >> $(DJANGO_SETTINGS_BASE_FILE)
	python manage.py makemigrations sitepage
	-$(GIT_ADD) sitepage/*.py
	-$(GIT_ADD) sitepage/migrations/*.py

.PHONY: wagtail-urls-default
wagtail-urls-default:
	@echo "$$WAGTAIL_URLS" > $(DJANGO_URLS_FILE)

.PHONY: wagtail-urls-home-default
wagtail-urls-home-default:
	@echo "$$WAGTAIL_URLS_HOME" >> $(DJANGO_URLS_FILE)

# --------------------------------------------------------------------------------
#  Webpack targets
# --------------------------------------------------------------------------------

.PHONY: webpack-init-default
webpack-init-default: npm-init
	@echo "$$WEBPACK_CONFIG_JS" > webpack.config.js
	-$(GIT_ADD) webpack.config.js
	npm install --save-dev webpack webpack-cli webpack-dev-server
	$(ADD_DIR) src/
	@echo "$$WEBPACK_INDEX_JS" > src/index.js
	-$(GIT_ADD) src/index.js
	@echo "$$WEBPACK_INDEX_HTML" > index.html
	-$(GIT_ADD) index.html

.PHONY: webpack-init-reveal-default
webpack-init-reveal-default: npm-init
	@echo "$$WEBPACK_REVEAL_CONFIG_JS" > webpack.config.js
	-$(GIT_ADD) webpack.config.js
	npm install --save-dev webpack webpack-cli webpack-dev-server
	$(ADD_DIR) src/
	@echo "$$WEBPACK_REVEAL_INDEX_JS" > src/index.js
	-$(GIT_ADD) src/index.js
	@echo "$$WEBPACK_REVEAL_INDEX_HTML" > index.html
	-$(GIT_ADD) index.html

# =================================================================================
# Title-case single-line phony target rules
#
# Use Title case for some phony targets E.g. `make lint` performs linting and
# can't be used to commit & push the results. Use Lint instead for such cases.
# =================================================================================

.PHONY: Clean-default
Clean-default: git-commit-message-clean git-push

.PHONY: Init-default
Init-default: git-commit-message-init git-push

.PHONY: Lint-default
Lint-default: git-commit-message-lint git-push

# =================================================================================
# Single-line phony target rules
# =================================================================================

.PHONY: actions-default
actions-default: git-commit-message-actions git-push

.PHONY: aws-check-env-default
aws-check-env-default: aws-check-env-profile aws-check-env-region

.PHONY: c-default
c-default: git-commit-message git-push

.PHONY: ce-default
ce-default: git-commit-edit git-push

.PHONY: clean-default
clean-default: django-clean

.PHONY: comment-default
comment-default: git-commit-message-comment git-push

.PHONY: cp-default
cp-default: git-commit-message git-push

.PHONY: db-dump-default
db-dump-default: eb-export

.PHONY: db-export-default
db-export-default: eb-export

.PHONY: db-init-default
db-init-default: django-db-init-postgres

.PHONY: dbshell-default
dbshell-default: django-db-shell

.PHONY: d-default
d-default: deploy

.PHONY: deploy-default
deploy-default: eb-deploy

.PHONY: deps-default
deps-default: pip-deps

.PHONY: dump-default
dump-default: db-dump

.PHONY: e-default
e-default: edit

.PHONY: edit-default
edit-default: readme-edit

.PHONY: empty-default
empty-default: git-commit-empty git-push

.PHONY: fp-default
fp-default: git-push-force

.PHONY: freeze-default
freeze-default: pip-freeze git-push

.PHONY: git-commit-push-default
git-commit-push-default: git-commit git-push

.PHONY: git-up-default
git-up-default: git-set-upstream

.PHONY: h-default
h-default: help

.PHONY: ignore-default
ignore-default: git-commit-message-ignore git-push

.PHONY: init-default
init-default: python-venv-check django-init-wagtail django-serve

.PHONY: install-default
install-default: pip-install

.PHONY: i-default
i-default: install

.PHONY: l-default
l-default: make-list-targets

.PHONY: last-default
last-default: git-commit-last git-push

.PHONY: lint-default
lint-default: django-lint

.PHONY: list-targets-default
list-targets-default: make-list-targets

.PHONY: list-targets-deps-default
list-targets-deps-default: make-list-targets-deps

.PHONY: list-defines-default
list-defines-default: make-list-defines

.PHONY: migrate-default
migrate-default: django-migrate

.PHONY: migrations-default
migrations-default: django-migrations-make

.PHONY: migrations-show-default
migrations-show-default: django-migrations-show

.PHONY: mk-default
mk-default: git-commit-message-project-custom git-push

.PHONY: open-default
open-default: open

.PHONY: o-default
o-default: django-open

.PHONY: readme-default
readme-default: git-commit-message-readme git-push

.PHONY: rename-default
rename-default: git-commit-message-rename git-push

.PHONY: reword-default
reword-default: git-commit-message-reword git-push

.PHONY: s-default
s-default: serve

.PHONY: sdist-default
sdist-default: python-sdist

.PHONY: serve-default
serve-default: django-serve

.PHONY: shell-default
shell-default: django-shell

.PHONY: sort-default
sort-default: git-commit-message-sort git-push

.PHONY: sqlmigrate
sqlmigrate: django-sqlmigrate

.PHONY: static-default
static-default: django-static

.PHONY: su-default
su-default: django-su

.PHONY: test-default
test-default: npm-install django-static pip-install-test django-test

.PHONY: t-default
t-default: test

.PHONY: typo-default
typo-default: git-commit-message-typo git-push

.PHONY: urls-default
urls-default: django-urls-show

# =================================================================================
# .NOT_PHONY!
# =================================================================================

$(PROJECT_CUSTOM_FILE):
	@echo "$$PROJECT_CUSTOM" > $@
	-$(GIT_ADD) $@

$(GIT_COMMIT_IGNORE_FILE):
	@echo "$$GIT_COMMIT_IGNORE" > $@
	-$(GIT_ADD) $@

# =================================================================================
# Allow customizing rules defined in this Makefile with rules defined in
# $(PROJECT_CUSTOM_FILE)
# =================================================================================

%: %-default  # https://stackoverflow.com/a/49804748
	@ true
